<?php
declare (strict_types = 1);

namespace Jenny\Car;
use Jenny;

class Filter extends \Jenny\Filter
{

public function Preset() : ?\Genelet\Gerror  {
  $err = parent::Preset();
  if ($err !== null) { return $err; }

  $ARGS =& $_REQUEST;
  $role = $this->Role_name;
  $action = $this->Action;
  $obj = $this->Component;

  return null;
}

public function Before(object &$model, array &$extra, array &$nextextra, array &$onceextra=null)  : ?\Genelet\Gerror {
  $err = parent::Before($model, $extra, $nextextra, $onceextra);
  if ($err !== null) { return $err; }

  $ARGS =& $_REQUEST;
  $role = $this->Role_name;
  $action = $this->Action;
  $obj = $this->Component;

  return null;
}

public function After(object $model, array $onceextra=null) : ?\Genelet\Gerror {
  $err = parent::After($model, $onceextra);
  if ($err !== null) { return $err; }

  $ARGS =& $_REQUEST;
  $role = $this->Role_name;
  $action = $this->Action;
  $obj = $this->Component;

  $loc = $this->server_url . '/jenny/cars/';

  if ($action==="topics") {
    $json_data = file_get_contents($loc . 'result.json');
    $obj = json_decode($json_data, true);

    foreach ($model->LISTS as $k => $item) {
      $make = strtolower(str_replace(" ", "_", $item["MAKE_NAME_NM"]));
      $model->LISTS[$k]["src"] = $loc . $obj[$make]["icon"];
      $model->LISTS[$k]["ON"] = date_format(date_create($item["RECALL_DATE_DTE"]), 'm/d/Y');
    }   
  } elseif ($action==="edit") {
    $json_data = file_get_contents($loc . 'result.json');
    $obj = json_decode($json_data, true);

    $item =& $model->LISTS[0];
    $model->LISTS[0]["ON"] = date_format(date_create($item["RECALL_DATE_DTE"]), 'M d, Y');
    $make = strtolower(str_replace(" ", "_", $item["MAKE_NAME_NM"]));
    $item["src"] = $loc . $obj[$make]["icon"];
    $model = strtolower($item["MODEL_NAME_NM"]);
    if (preg_match("/^([a-z]) ([a-z].*)$/", $model, $matches)) {
      $model =  $matches[1]."-".$matches[2];
    }
    $a = explode(" ", $model, 3);
    $short = $a[0];
    if (strlen($short)==1) {
      $short .= "_".$a[1];
    }
    $year = $item["YEAR"];
    $p1 = "";
    $p2 = "";
    foreach ($obj[$make] as $k=>$v) {
      if ($k==="icon") { continue; }
      if (preg_match("/^".$make."_$short.+$year.[a-z]$/", $k)) {
        $p1 = $k;
	break;
      } elseif (preg_match("/^".$make."_$short.+.[a-z]$/", $k)) {
        $p2 = $k;
      }
    }
    if ($p1 !== "") {
      $item["photo"] = $loc . $make . "/". $p1;
    } elseif ($p2 !== "") {
      $item["photo"] = $loc . $make . "/". $p2;
    }
  }

  return null;
}

}
