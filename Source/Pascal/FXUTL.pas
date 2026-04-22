unit FXUTL;
interface

PROCEDURE LStrToCharStr(CONST ALString : STRING;
                        VAR   ACharArray;
                        CharArraySize : BYTE);

PROCEDURE CharStrToLStr(CONST ACharArray; CharArraySize : BYTE;
                        VAR   ALString : STRING);

implementation

PROCEDURE LStrToCharStr(CONST ALString : STRING;
                        VAR   ACharArray;
                        CharArraySize : BYTE);
VAR MaxLen : BYTE;
BEGIN
 MaxLen := ORD(ALString[0]);
 IF CharArraySize < MaxLen THEN
   MaxLen := CharArraySize;

 FillChar(ACharArray, CharArraySize, #32);{make sure CHAR fields are space padded}
 Move(ALString[1], ACharArray, MaxLen);
END;

PROCEDURE CharStrToLStr(CONST ACharArray; CharArraySize : BYTE;
                        VAR   ALString : STRING);
{REQUIRES ALString size to be greater than ACharArray size.}
BEGIN
 ALString[0] := CHAR(CharArraySize);
 Move(ACharArray, ALString[1], CharArraySize);
END;


end.
