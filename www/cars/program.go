package main

import (
"fmt"
	"io"
	"io/ioutil"
	"os"
	"bytes"
	"encoding/json"
	"strings"
	"net/http"
	"net/url"
	"golang.org/x/net/html"
	"net/http/cookiejar"
	"golang.org/x/net/publicsuffix"
)

const (
	TOP     = "https://www.izmostock.com/car-stock-photos-by-brand"
	STOCK   = "https://izmostock.photoshelter.com/gallery-collection/Ram-Stock-Photos"
)

func main() {
	brands, err := getProgram(TOP)
	if err !=nil { panic(err) }
	body, _ := json.Marshal(brands)
    fmt.Println(string(body))
	os.Exit(0)
}

func _doRequest(method, in, referer string, data url.Values, jar *cookiejar.Jar) (*http.Response, error) {
	u, err := url.Parse(in)
	if err != nil { return nil, err }
	var r *http.Request
	if method=="POST" {
		str := data.Encode()
		r, err = http.NewRequest(method, in, strings.NewReader(str))
		if err != nil { return nil, err }
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	} else {
		r, err = http.NewRequest(method, in, nil)
		if err != nil { return nil, err }
	}
	r.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36")
	if referer != "" { r.Header.Set("Referer", referer) }
	for _, cookie := range jar.Cookies(u) {
		r.AddCookie(cookie)
	}

	// no redirect, default is to follow 10 redirects
	// no jar in client because it is explicitely set up in r
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	resp, err := client.Do(r)
	if err != nil { return nil, err }
	if cookies := resp.Cookies(); cookies != nil {
		jar.SetCookies(u, cookies)
	}
	return resp, nil
}

func postResponse(in, referer string, data url.Values, jar *cookiejar.Jar) (*http.Response, error) {
	return _doRequest("POST", in, referer, data, jar)
}

func getResponse(in, referer string, jar *cookiejar.Jar) (*http.Response, error) {
	return _doRequest("GET", in, referer, nil, jar)
}
func getBody(in, referer string, jar *cookiejar.Jar) ([]byte, error) {
    res, err := getResponse(in, referer, jar)
    if err != nil { return nil, err }
    body, err := ioutil.ReadAll(res.Body)
    res.Body.Close()
	return body, err
}

func getSimple(url string) ([]byte, error) {
    res, err := http.Get(url)
    if err != nil { return nil, err }
    body, err := ioutil.ReadAll(res.Body)
    res.Body.Close()
    if err != nil { return nil, err }
	return body, err
}

func getParsed(in, referer string, jar *cookiejar.Jar) (*html.Tokenizer, error) {
    body, err := getBody(in, referer, jar)
    if err != nil { return nil, err }
	return html.NewTokenizer(bytes.NewReader(body)), nil
}

func writeParsed(fn, in, referer string, jar *cookiejar.Jar) error {
    body, err := getBody(in, referer, jar)
    if err != nil { return err }
	return ioutil.WriteFile(fn, body, 0644)
}

func getBrand(car, brand, referer string, jar *cookiejar.Jar) (map[string]string, error) {
	ref := make(map[string]string)

	z, err := getParsed(brand, referer, jar)
    if err != nil { return nil, err }

	in := false

	for {
		tt := z.Next()
		switch tt {
		case html.ErrorToken:
			e := z.Err()
			if e==io.EOF { return ref, nil }
			return nil, e
		case html.EndTagToken:
			t := z.Token()
			switch t.Data {
			case "ul":
				if in {
					in = false
				}
			default:
			}
		case html.StartTagToken:
			t := z.Token()
			switch t.Data {
			case "img":
				if in {
					src := ""
					alt := ""
					for _, item := range t.Attr {
						if item.Key=="src" {
							src = item.Val
						}
						if item.Key=="alt" {
							alt = item.Val
						}
						if item.Key=="data-gal-img-thumb" {
							hash := make(map[string]string)
							err := json.Unmarshal([]byte(item.Val), &hash)
							if err != nil { return nil, err }
							alt = hash["CAPTION"]
						}
					}
					if src=="/img/mvc/MyImages/uploader-badge.png" || alt=="" {
						break;
					}
					full := strings.TrimSpace(alt)
					a := strings.Split(src, ".")
					name := strings.ReplaceAll(full, " ", "_")
					name  = strings.ReplaceAll(name, "/", "_")
					name  = strings.ReplaceAll(name, "’s", "_")
					name  = strings.ReplaceAll(name, "'", "_")
					name  = strings.ToLower(name) + "." + a[len(a)-1]
					ref[name] = full
					name = car + "/" + name
					if _, err = os.Stat(name); os.IsNotExist(err) {
						if err = writeParsed(name, src, brand, jar); err != nil {
							return nil, err
						}
					}
				}
			case "ul":
				for _, item := range t.Attr {
					if item.Key=="class" && (item.Val=="thumbs gallery_list" || item.Val=="thumbs gallery_thumbs") {
						in = true
					}
				}
			default:
			}
		default:
		}
	}

	return ref, nil
}

func getProgram(top string) (map[string]map[string]string, error) {
	all := make(map[string]map[string]string)

    jar, err := cookiejar.New(&cookiejar.Options{PublicSuffixList: publicsuffix.List})
    if err != nil { return nil, err }

	z, err := getParsed(top, "", jar)
    if err != nil { return nil, err }

	in := false

	for {
		tt := z.Next()
		switch tt {
		case html.ErrorToken:
			e := z.Err()
			if e==io.EOF { return all, nil }
			return nil, e
		case html.EndTagToken:
			t := z.Token()
			switch t.Data {
			case "article":
				in = false;
			default:
			}
		case html.StartTagToken:
			t := z.Token()
			switch t.Data {
			case "a":
				if in {
					href := ""
					img  := ""
					for _, item := range t.Attr {
						k := item.Key
						v := item.Val
						if k=="href" {
							href = v
						}
					}
					if z.Next() == html.TextToken {
						z.Next()
					}
					t = z.Token()
					for _, item := range t.Attr {
						k := item.Key
						v := item.Val
						if k=="src" {
							img = v
						}
					}
					z.Next()
					t = z.Token()
					z.Next()
					t = z.Token()
					dir := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(t.Data), " ", "_"))
					a := strings.Split(img, ".")
					car := dir + "." + a[len(a)-1]
					if _, err = os.Stat(car); os.IsNotExist(err) {
						if err = writeParsed(car, img, top, jar); err != nil {
							return nil, err
						}
					}
					if _, err = os.Stat(dir); os.IsNotExist(err) {
						if err = os.Mkdir(dir, os.ModeDir); err != nil {
							return nil, err
						}
					}
					ref, err := getBrand(dir, href, top, jar)
					if err != nil {
						return nil, err
					}
					all[dir] = ref
				}
			case "article":
				in = true
			default:
			}
		default:
		}
	}

	return all, nil
}
