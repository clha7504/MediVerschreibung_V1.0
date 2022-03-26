pragma solidity ^0.4.17;

contract Medi {

    struct Verschreibung {
        uint verschreibung_ID;
        uint patienten_ID;
        uint medi_ID; // aus Hospindex
        string medi_Bezeichnung; // aus Hospindex
        string medi_Anwendung;
        string kommentar;
        address verschreiber_ID;
        bool aktiv;
        uint timeStamp;
        uint timeDeaktivierung;
        
    }

    struct Patient {
        uint patienten_ID;
        string vorname;
        string nachname;
        string anschrift;
        address angelegtVon;
        uint timeStamp;
    }

    struct Berechtigung {
        address verschreiber_ID;
        bool berechtigt; // Könnte durch User-Rollen ergänzt werden.
    }

    // LogMutation und LogLoeschen erzeugen einen Event, wenn ein Attribut vom Struct Verschreibung, oder Patient mutiert wird. Bzw. wenn ein Objekt gelöscht wird.
    // LogBerechtigung erzeugt einen Event, wenn die Berechtigung von einem User angepasst wurde
    event LogMutation(address indexed sender, uint indexed nummer, string aktion, string newMessage, string oldMessage, uint now);
    event LogLoeschen(address indexed sender, string message, uint indexed nummer, uint now);
    event LogBerechtigung(address indexed sender, address indexed verschreiber_ID, string aktion, bool neueBerechtigung, bool alteBerechtigung, uint now);

    uint public anzahlVerschreibungen = 0;
    uint public anzahlPatienten = 0;
    bool berechtigt = false;

    // Erstellt ein Mapping für sämtliche Structs (Verschreibungen und Patienten) mit ihrem Key (verschreibung_ID und patienten_ID)
    mapping(uint => Verschreibung) public verschreibungen;
    mapping(uint => Patient) public patienten;

    // Erstellt ein Mapping für die Berechtigung wer die Funktionen ausüben darf. Die Funktionen zum Löschen von Verschreibungen und Patienten
    // sind davon ausgenommen. Diese beiden Funktionen dürfen nur vom User gelöscht werden, welcher die Daten initialiert hat.
    mapping(address => Berechtigung) public berechtigungen;

    // Funktion zur Aktivierung, oder Deaktivierung einer Berechtigung.
    function berechtigen(address adresse, bool berechtigt) {
        bool hilfs4 = berechtigungen[adresse].berechtigt;
        berechtigungen[adresse].berechtigt = berechtigt;
        emit LogBerechtigung(msg.sender, adresse, "Neue Berechtigung", berechtigt, hilfs4, now);
    }
    
    // Funktion zum Anlegen einer neuen Verschreibung (Bei Ausstellung vom Rezept)
    function neueVerschreibung(uint _patienten_ID, uint _medi_ID, string memory _medi_Bezeichnung, string memory _medi_Anwendung, string memory _kommentar) public {
        anzahlVerschreibungen = anzahlVerschreibungen + 1;
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        require(patienten[anzahlVerschreibungen].timeStamp != 0); // Neue Verschreibung nur möglich, wenn Patient angelegt ist.
        verschreibungen[anzahlVerschreibungen] = Verschreibung(anzahlVerschreibungen, _patienten_ID, _medi_ID, _medi_Bezeichnung, _medi_Anwendung, _kommentar, msg.sender, true, now, 0);
    }
    // TimeStamp kann konvertiert werden: http://www.unixtimestamp.com/

    // Funktion die Deaktivierung von einer Verschreibung (
    function deaktivieren_ver(uint verschreibung_ID) public {
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        if (verschreibungen[verschreibung_ID].aktiv) {
            verschreibungen[verschreibung_ID].aktiv = false;
            verschreibungen[verschreibung_ID].timeDeaktivierung = now;
        }
    }

    // Funktion für die Modifikation vom Attribut "medi_Anwendung".
    function mod_anwendung(uint verschreibung_ID, string memory neueAnwendung) public {
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        string memory hilfs1 = verschreibungen[verschreibung_ID].medi_Anwendung;
        verschreibungen[verschreibung_ID].medi_Anwendung = neueAnwendung;
        emit LogMutation(msg.sender, verschreibung_ID,  "Neue Anwendung", neueAnwendung, hilfs1, now);
    }

    // Funktion für die Modifikation vom Attribut "kommentar".
    function mod_kommentar(uint verschreibung_ID, string memory neuerKommentar) public {
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        string memory hilfs2 = verschreibungen[verschreibung_ID].kommentar;
        verschreibungen[verschreibung_ID].kommentar = neuerKommentar;
        emit LogMutation(msg.sender, verschreibung_ID, "Neuer Kommentar", neuerKommentar, hilfs2, now);
    }

    // Funktion zum Löschen einer Verschreibung
    function loeschen_ver(uint verschreibung_ID) public {
        require(msg.sender == verschreibungen[verschreibung_ID].verschreiber_ID);
        emit LogLoeschen(msg.sender, "Verschreibung wurde gelöscht", verschreibung_ID, now);
        delete verschreibungen[verschreibung_ID];        
    }

    // Funktion zum Anlegen von einem neuen Patienten
    function neuerPatient(string memory _vorname, string memory _nachname, string memory _anschrift) public {
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        anzahlPatienten = anzahlPatienten + 1;
        patienten[anzahlPatienten] = Patient(anzahlPatienten, _vorname, _nachname, _anschrift, msg.sender, now);
    }

    // Funktion zur Modifikation vom Attribut "Anschrift"
    function mod_anschrift(uint patienten_ID, string memory neueAnschrift) public {
        require(berechtigungen[msg.sender].berechtigt == true); // User bzw. Verschreiber muss berechtigt sein
        string memory hilfs3 = patienten[patienten_ID].anschrift;
        patienten[patienten_ID].anschrift = neueAnschrift;
        emit LogMutation(msg.sender, patienten[patienten_ID].patienten_ID, "Neue Anschrift", neueAnschrift, hilfs3, now);
    }

    // Funktion zum Löschen von einem Patienten
    function loeschen_pat(uint patienten_ID) public {
        require(msg.sender == patienten[patienten_ID].angelegtVon);
        emit LogLoeschen(msg.sender, "Patient wurde gelöscht", patienten_ID, now);
        delete patienten[patienten_ID];
    }

}

// 9.  Berechtigungen zur Abfrage der Mappings funktionieren nicht
// 10. Allenfalls Skript schreiben um die events auszulesen: https://www.youtube.com/watch?v=BduMOagAuKs
// 