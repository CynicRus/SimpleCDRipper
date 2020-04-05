unit ucdtrack;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils;
type
   TAddress = array[0..3] of byte;
   { TCDTrack }

   TCDTrack = record
    address: cardinal;
    len: cardinal;
    class operator Equal (t1, t2: TCDTrack)B: Boolean;
    end;

     { TAudioTrack }

   TAudioTrack = record
    Number: byte;
    Artist: string;
    Title: string;
    Start: TAddress;
    Duration: TDateTime;
    Length: string;
    class operator Equal (t1, t2: TAudioTrack)B: Boolean;
  end;

implementation

{ TAudioTrack }

class operator TAudioTrack.Equal(t1, t2: TAudioTrack)B: Boolean;
begin
  B:= CompareText(t1.Title,t2.Title) = 0;
end;

{ TCDTrack }

class operator TCDTrack.Equal(t1, t2: TCDTrack)B: Boolean;
begin
  B:= (t1.address = t2.address) and (t1.len = t2.len);
end;

end.

