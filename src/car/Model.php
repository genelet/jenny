<?php
declare (strict_types = 1);

namespace Jenny\Car;
use Jenny;

class Model extends \Jenny\Model
{
    public function years(...$extra) : ?\Genelet\Gerror {
	$this->LISTS = [];
        return $this->Select_sql($this->LISTS,
            "select year, count(*) as counts from Book3_csv where CATEGORY_ETXT in ('Car','SUV') group by year order by year desc");
    }

    public function makes(...$extra) : ?\Genelet\Gerror {
	$this->LISTS = [];
        return $this->Select_sql($this->LISTS,
            "select MAKE_NAME_NM,count(*) as counts from Book3_csv where CATEGORY_ETXT in ('Car','SUV') group by MAKE_NAME_NM");
    }

    public function history(...$extra) : ?\Genelet\Gerror {
	$this->LISTS = [];
        return $this->Select_sql($this->LISTS,
            "select log_id, theday, num, status from log_download order by log_id desc limit 20");
    }
};
