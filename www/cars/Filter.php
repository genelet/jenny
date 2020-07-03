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

  if ($action==="topics") {
    $json_data = file_get_contents($this->document_root . '/cars/result.json');
    $obj = json_decode($json_data, true);

    foreach ($model->LISTS as $k => $item) {
      $make = strtolower(str_replace(" ", "_", $item["MAKE_NAME_NM"]));
      $model->LISTS[$k]["src"] = $obj[$make]["icon"];
    }   
  } elseif ($action==="edit") {
    $json_data = file_get_contents($this->document_root . '/cars/result.json');
    $obj = json_decode($json_data, true);

    $item =& $model->LISTS[0];
    $make = strtolower(str_replace(" ", "_", $item["MAKE_NAME_NM"]));
    $item["src"] = $obj[$make]["icon"];
    $model = strtolower($item["MODEL_NAME_NM"]);
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
      $item["photo"] = $make . "/". $p1;
    } elseif ($p2 !== "") {
      $item["photo"] = $make . "/". $p2;
    }
  }

  return null;
}

}
