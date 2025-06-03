/* Структура контроллера одного направления */
typedef TLight {
    int color;
    bool sense;
}

mtype = { GREEN, RED }

TLight NS, EW, SD, WN, WD, DN;

// Количество пересечений
#define N 6
// Количество направлений
#define M 6
// Id направлений
#define NSid 0
#define EWid 1
#define SDid 2
#define WNid 3
#define WDid 4
#define DNid 5

/* Очереди мьютексов для пересечений */
chan lock[N] = [M] of { int };

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

init {
    atomic {
        NS.color = RED;
        EW.color = RED;
        SD.color = RED;
        WN.color = RED;
        WD.color = RED;
        DN.color = RED;
        NS.sense = false;
        EW.sense = false;
        SD.sense = false;
        WN.sense = false;
        WD.sense = false;
        DN.sense = false;

        run Traffic();
        run NSproc();
        run EWproc(); 
        run SDproc();
        run WNproc();
        run WDproc();
        run DNproc();
    }
}

/* Моделирование траффика. Если не активирован сенсор - активируем */
proctype Traffic() {
    do
    :: !NS.sense -> NS.sense = true
    :: !EW.sense -> EW.sense = true
    :: !SD.sense -> SD.sense = true
    :: !WN.sense -> WN.sense = true
    :: !WD.sense -> WD.sense = true
    :: !DN.sense -> DN.sense = true
    od
}

/* Процесс для каждого направления (сфетофора) */
proctype NSproc() {
    do
    :: NS.sense -> {
        // Добавляем наш id в канал
        lock[3] ! NSid;
        // Ждём пока до него дойдёт очередь
        lock[3] ? <NSid>;
        // Аналогично
        lock[5] ! NSid;
        lock[5] ? <NSid>;

        // Выключаем сенсор и устанавливаем зелёный свет
        NS.sense = false;
        NS.color = GREEN;

        /* Происходит проезд */

        /* Устанавливаем красный свет */
        NS.color = RED;
        // Освобождаем канал от своего id
        lock[3] ? NSid;
        lock[5] ? NSid;
    }
    od
}

proctype EWproc() {
    do
    :: EW.sense -> {
        lock[1] ! EWid;
        lock[1] ? <EWid>;
        lock[2] ! EWid;
        lock[2] ? <EWid>;
        lock[3] ! EWid;
        lock[3] ? <EWid>;
        lock[4] ! EWid;
        lock[4] ? <EWid>;
        
        EW.sense = false;
        EW.color = GREEN;
        /* */
        EW.color = RED;
        lock[1] ? EWid;
        lock[2] ? EWid;
        lock[3] ? EWid;
        lock[4] ? EWid;
    }
    od
}

proctype SDproc() {
    do
    :: SD.sense -> {
        lock[2] ! SDid;
        lock[2] ? <SDid>;
        lock[5] ! SDid;
        lock[5] ? <SDid>;
        
        SD.sense = false;
        SD.color = GREEN;
        /* */
        SD.color = RED;
        lock[2] ? SDid;
        lock[5] ? SDid;
    }
    od
}

proctype WNproc() {
    do
    :: WN.sense -> {
        lock[4] ! WNid;
        lock[4] ? <WNid>;
        lock[5] ! WNid;
        lock[5] ? <WNid>;
        
        WN.sense = false;
        WN.color = GREEN;
        /* */
        WN.color = RED;
        lock[4] ? WNid;
        lock[5] ? WNid;
    }
    od
}

proctype WDproc() {
    do
    :: WD.sense -> {
        lock[0] ! WDid;
        lock[0] ? <WDid>;
        lock[1] ! WDid;
        lock[1] ? <WDid>;
        
        WD.sense = false;
        WD.color = GREEN;
        /* */
        WD.color = RED;
        lock[0] ? WDid;
        lock[1] ? WDid;
    }
    od
}

proctype DNproc() {
    do
    :: DN.sense -> {
        lock[0] ! DNid;
        lock[0] ? <DNid>;
        lock[2] ! DNid;
        lock[2] ? <DNid>;
        lock[3] ! DNid;
        lock[3] ? <DNid>;
        
        DN.sense = false;
        DN.color = GREEN;
        /* */
        DN.color = RED;
        lock[0] ? DNid;
        lock[2] ? DNid;
        lock[3] ? DNid;
    }
    od
}