/* Структура контроллера одного направления */
typedef TLight {
    int color;
    bool sense;
}

mtype = { GREEN, RED }

TLight NS, EW, SD, WN, DN;

// Количество пересечений
#define N 4
// Количество направлений
#define M 5
// Id направлений
#define NSid 0
#define EWid 1
#define SDid 2
#define WNid 3
#define DNid 4

/* Очереди мьютексов для пересечений */
chan lock[N] = [M] of { int };

/* Условия безопасности */
ltl safetyNS { [] !((NS.color == GREEN) && (EW.color == GREEN || SD.color == GREEN || WN.color == GREEN || DN.color == GREEN)) }
ltl safetyEW { [] !((EW.color == GREEN) && (NS.color == GREEN || SD.color == GREEN || WN.color == GREEN || DN.color == GREEN)) }
ltl safetySD { [] !((SD.color == GREEN) && (NS.color == GREEN || EW.color == GREEN || WN.color == GREEN || DN.color == GREEN)) }
ltl safetyWN { [] !((WN.color == GREEN) && (NS.color == GREEN || SD.color == GREEN || EW.color == GREEN)) }
ltl safetyDN { [] !((DN.color == GREEN) && (NS.color == GREEN || EW.color == GREEN || SD.color == GREEN)) }

/* Условия живости */
ltl livenessNS { [] ((NS.sense && (NS.color == RED)) -> <> (NS.color == GREEN)) }
ltl livenessEW { [] ((EW.sense && (EW.color == RED)) -> <> (EW.color == GREEN)) }
ltl livenessSD { [] ((SD.sense && (SD.color == RED)) -> <> (SD.color == GREEN)) }
ltl livenessWN { [] ((WN.sense && (WN.color == RED)) -> <> (WN.color == GREEN)) }
ltl livenessDN { [] ((DN.sense && (DN.color == RED)) -> <> (DN.color == GREEN)) }

/* Условия справедливости */
ltl fairnessNS { [] <> !((NS.color == GREEN) && NS.sense) }
ltl fairnessEW { [] <> !((EW.color == GREEN) && EW.sense) }
ltl fairnessSD { [] <> !((SD.color == GREEN) && SD.sense) }
ltl fairnessWN { [] <> !((WN.color == GREEN) && WN.sense) }
ltl fairnessDN { [] <> !((DN.color == GREEN) && DN.sense) }

init {
    atomic {
        NS.color = RED;
        EW.color = RED;
        SD.color = RED;
        WN.color = RED;
        DN.color = RED;
        NS.sense = false;
        EW.sense = false;
        SD.sense = false;
        WN.sense = false;
        DN.sense = false;

        run Traffic();
        run NSproc();
        run EWproc(); 
        run SDproc();
        run WNproc();
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
    :: !DN.sense -> DN.sense = true
    od
}

/* Процесс для каждого направления (сфетофора) */
proctype NSproc() {
    do
    :: NS.color == GREEN -> {
        NS.color = RED;
        // Освобождаем канал от своего id
        lock[1] ? NSid;
        lock[3] ? NSid;
    }
    :: NS.sense && NS.color == RED -> {
        // Добавляем наш id в канал
        lock[1] ! NSid;
        // Ждём пока до него дойдёт очередь
        lock[1] ? <NSid>;
        // Аналогично
        lock[3] ! NSid;
        lock[3] ? <NSid>;
        NS.sense = false;
        NS.color = GREEN;
    }
    od
}

proctype EWproc() {
    do
    :: EW.color == GREEN -> {
        EW.color = RED;
        lock[0] ? EWid;
        lock[1] ? EWid;
        lock[2] ? EWid;
    }
    :: EW.sense && EW.color == RED -> {
        lock[0] ! EWid;
        lock[0] ? <EWid>;
        lock[1] ! EWid;
        lock[1] ? <EWid>;
        lock[2] ! EWid;
        lock[2] ? <EWid>;
        
        EW.sense = false;
        EW.color = GREEN;
    }
    od
}

proctype SDproc() {
    do
    :: SD.color == GREEN -> {
        SD.color = RED;
        lock[0] ? SDid;
        lock[3] ? SDid;
    }
    :: SD.sense && SD.color == RED -> {
        lock[0] ! SDid;
        lock[0] ? <SDid>;
        lock[3] ! SDid;
        lock[3] ? <SDid>;
        
        SD.sense = false;
        SD.color = GREEN;
    }
    od
}

proctype WNproc() {
    do
    :: WN.color == GREEN -> {
        WN.color = RED;
        lock[2] ? WNid;
        lock[3] ? WNid;
    }
    :: WN.sense && WN.color == RED -> {
        lock[2] ! WNid;
        lock[2] ? <WNid>;
        lock[3] ! WNid;
        lock[3] ? <WNid>;
        
        WN.sense = false;
        WN.color = GREEN;
    }
    od
}

proctype DNproc() {
    do
    :: DN.color == GREEN -> {
        DN.color = RED;
        lock[0] ? DNid;
        lock[1] ? DNid;
    }
    :: DN.sense && DN.color == RED -> {
        lock[0] ! DNid;
        lock[0] ? <DNid>;
        lock[1] ! DNid;
        lock[1] ? <DNid>;
        
        DN.sense = false;
        DN.color = GREEN;
    }
    od
}