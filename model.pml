/* Структура контроллера одного направления */
typedef TLight {
    int color;
    bool sense;
    bool req;
    bool lock;
}

mtype = { GREEN, RED }

TLight NS, EW, SD, WN, WD, DN;

/* Условия безопасности */
ltl safetyNS { [] !((NS.color == GREEN) && (EW.color == GREEN || SD.color == GREEN || WN.color == GREEN || DN.color == GREEN)) }
ltl safetyEW { [] !((EW.color == GREEN) && (NS.color == GREEN || SD.color == GREEN || WN.color == GREEN || WD.color == GREEN || DN.color == GREEN)) }
ltl safetySD { [] !((SD.color == GREEN) && (NS.color == GREEN || EW.color == GREEN || WN.color == GREEN || DN.color == GREEN)) }
ltl safetyWN { [] !((WN.color == GREEN) && (NS.color == GREEN || SD.color == GREEN || EW.color == GREEN)) }
ltl safetyWD { [] !((WD.color == GREEN) && (EW.color == GREEN || DN.color == GREEN)) }
ltl safetyDN { [] !((DN.color == GREEN) && (NS.color == GREEN || EW.color == GREEN || SD.color == GREEN || WD.color == GREEN)) }

/* Условия живости */
ltl livenessNS { [] ((NS.sense && (NS.color == RED)) -> <> (NS.color == GREEN)) }
ltl livenessEW { [] ((EW.sense && (EW.color == RED)) -> <> (EW.color == GREEN)) }
ltl livenessSD { [] ((SD.sense && (SD.color == RED)) -> <> (SD.color == GREEN)) }
ltl livenessWN { [] ((WN.sense && (WN.color == RED)) -> <> (WN.color == GREEN)) }
ltl livenessWD { [] ((WD.sense && (WD.color == RED)) -> <> (WD.color == GREEN)) }
ltl livenessDN { [] ((DN.sense && (DN.color == RED)) -> <> (DN.color == GREEN)) }

/* Условия справедливости */
ltl fairnessNS { [] <> !((NS.color == GREEN) && NS.sense) }
ltl fairnessEW { [] <> !((EW.color == GREEN) && EW.sense) }
ltl fairnessSD { [] <> !((SD.color == GREEN) && SD.sense) }
ltl fairnessWN { [] <> !((WN.color == GREEN) && WN.sense) }
ltl fairnessWD { [] <> !((WD.color == GREEN) && WD.sense) }
ltl fairnessDN { [] <> !((DN.color == GREEN) && DN.sense) }

/* Моделирование траффика */
active proctype Traffic() {
    do
    :: atomic {
        /* Если нигде нет машин - устанавливаем везде */
        if
        :: (!(
            NS.sense || EW.sense || SD.sense ||
            WN.sense || WD.sense || DN.sense
        )) ->
            NS.sense = true;
            EW.sense = true;
            SD.sense = true;
            WN.sense = true;
            WD.sense = true;
            DN.sense = true;
        fi
    }

    /* Для каждого направления */
    /* - Если есть машины и нет запроса - устанавливаем запрос */
    /* - Если есть машины и горит зелёный - убираем машины (считаем что проехали) */

    :: (NS.sense && !NS.req) ->
        NS.req = true;
    :: (NS.sense && NS.color == GREEN) ->
        NS.sense = false;

    :: (EW.sense && !EW.req) ->
        EW.req = true;
    :: (EW.sense && EW.color == GREEN) ->
        EW.sense = false;

    :: (SD.sense && !SD.req) ->
            SD.req = true;
    :: (SD.sense && SD.color == GREEN) ->
        SD.sense = false;

    :: (WN.sense && !WN.req) ->
            WN.req = true;
    :: (WN.sense && WN.color == GREEN) ->
        WN.sense = false;

    :: (WD.sense && !WD.req) ->
        WD.req = true;
    :: (WD.sense && WD.color == GREEN) ->
        WD.sense = false;

    :: (DN.sense && !DN.req) ->
        DN.req = true;
    :: (DN.sense && DN.color == GREEN) ->
        DN.sense = false;
    od
}

/* Процесс для каждого направления (сфетофора) */
active proctype NSproc() {
    do
    /* Если есть запрос и нет блокировки переходим в atomic блок */
    :: (NS.req && !NS.lock) ->
        atomic {
            /* Если нигде больше нет блокировок, устанавливаем блокировку и цвет зелёный */
            if
            :: (!EW.lock && !SD.lock && !WN.lock && !DN.lock) ->
                NS.lock = true;
                NS.color = GREEN;
            fi
        }
    /* Если есть блокировка и нет запроса - красный */
    :: (NS.lock && !NS.req) ->
        NS.color = RED;
        NS.lock = false;
    /* Если нет машин и есть запрос - убираем запрос */
    :: (!NS.sense && NS.req) ->
        NS.req = false;
    od
}

active proctype EWproc() {
    do
    :: (EW.req && !EW.lock) ->
        atomic {
            if
            :: (!NS.lock && !SD.lock && !WN.lock && !WD.lock && !DN.lock) ->
                EW.lock = true;
                EW.color = GREEN;
            fi
        }
    :: (EW.lock && !EW.req) ->
        EW.color = RED;
        EW.lock = false;
    :: (!EW.sense && EW.req) ->
        EW.req = false;
    od
}

active proctype SDproc() {
    do
    :: (SD.req && !SD.lock) ->
        atomic {
            if
            :: (!NS.lock && !EW.lock && !WN.lock && !DN.lock) ->
                SD.lock = true;
                SD.color = GREEN;
            fi
        }
    :: (SD.lock && !SD.req) ->
        SD.color = RED;
        SD.lock = false;
    :: (!SD.sense && SD.req) ->
        SD.req = false;
    od
}

active proctype WNproc() {
    do
    :: (WN.req && !WN.lock) ->
        atomic {
            if
            :: (!NS.lock &&  !EW.lock && !SD.lock) ->
                WN.lock = true;
                WN.color = GREEN;
            fi
        }
    :: (WN.lock && !WN.req) ->
        WN.color = RED;
        WN.lock = false;
    :: (!WN.sense && WN.req) ->
        WN.req = false;
    od
}

active proctype WDproc() {
    do
    :: (WD.req && !WD.lock) ->
        atomic {
            if
            :: (!EW.lock && !DN.lock) ->
                WD.lock = true;
                WD.color = GREEN;
            fi
        }
    :: (WD.lock && !WD.req) ->
        WD.color = RED;
        WD.lock = false;
    :: (!WD.sense && WD.req) ->
        WD.req = false;
    od
}

active proctype DNproc() {
    do
    :: (DN.req && !DN.lock) ->
        atomic {
            if
            :: (!NS.lock && !EW.lock && !SD.lock && !WD.lock) ->
                DN.lock = true;
                DN.color = GREEN;
            fi
        }
    :: (DN.lock && !DN.req) ->
        DN.color = RED;
        DN.lock = false;
    :: (!DN.sense && DN.req) ->
        DN.req = false;
    od
}
