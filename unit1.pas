unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,Math,GraphUtil, Unit2;

type
  vmap =record
    val:array of array of integer;
    cmax,cmin:integer;
  end;
  { TForm1 }

  TForm1 = class(TForm)
    Button2: TButton;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Panel1: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  r0, r1, r2, v1, v2: vec4d;
  values: vmap;
  bmp: TBitmap;
  maxiter: integer;
  zoom: real;
  xoff, yoff, xoffalt, yoffalt: real;
  gradient: array of array[0..255] of Tcolor;
  gradientPic: Tbitmap;
  index:integer;
implementation



{$R *.lfm}

{ TForm1 }

function rotateXY(inVec: vec4d; angle: real): vec4d;
begin
  rotateXY.x := inVec.x * cos(angle) - inVec.y * sin(angle);
  rotateXY.y := inVec.x * sin(angle) + inVec.y * cos(angle);
  rotateXY.z := inVec.z;
  rotateXY.w := inVec.w;
end;

function rotateXZ(inVec: vec4d; angle: real): vec4d;
begin
  rotateXZ.x := inVec.x * cos(angle) - inVec.z * sin(angle);
  rotateXZ.y := inVec.y;
  rotateXZ.z := inVec.x * sin(angle) + inVec.z * cos(angle);
  rotateXZ.w := inVec.w;
end;

function rotateXW(inVec: vec4d; angle: real): vec4d;
begin
  rotateXW.x := inVec.x * cos(angle) - inVec.w * sin(angle);
  rotateXW.y := inVec.y;
  rotateXW.z := inVec.z;
  rotateXW.w := inVec.x * sin(angle) + inVec.w * cos(angle);
end;

function rotateYZ(inVec: vec4d; angle: real): vec4d;
begin
  rotateYZ.x := inVec.x;
  rotateYZ.y := inVec.y * cos(angle) - inVec.z * sin(angle);
  rotateYZ.z := inVec.y * sin(angle) + inVec.z * cos(angle);
  rotateYZ.w := inVec.w;
end;

function rotateYW(inVec: vec4d; angle: real): vec4d;
begin
  rotateYW.x := inVec.x;
  rotateYW.y := inVec.y * cos(angle) - inVec.w * sin(angle);
  rotateYW.z := inVec.z;
  rotateYW.w := inVec.y * sin(angle) + inVec.w * cos(angle);
end;

function rotateZW(inVec: vec4d; angle: real): vec4d;
begin
  rotateZW.x := inVec.x;
  rotateZW.y := inVec.y;
  rotateZW.z := inVec.z * cos(angle) - inVec.w * sin(angle);
  rotateZW.w := inVec.z * sin(angle) + inVec.w * cos(angle);

end;

function iterreal(mode: integer; x, y, px: real): real;
begin
  case mode of
    1: iterreal := x + px;
    2: iterreal := x * x - y * y + px;
    3: iterreal := x * x * x - 3 * x * y * y + px;
    4: iterreal := x * x * x * x + y * y * y * y - 6 * x * x * y * y + px;
    5: iterreal := x * x * x * x * x - 10 * x * x * x * y * y + 5 *
        x * y * y * y * y + px;
  end;
end;

function iterimg(mode: integer; x, y, py: real): real;
begin
  case mode of
    1: iterimg := y + py;
    2: iterimg := 2 * x * y + py;
    3: iterimg := 3 * x * x * y - y * y * y + py;
    4: iterimg := 4 * x * x * x * y - 4 * x * y * y * y + py;
    5: iterimg := y * y * y * y * y + 5 * x * x * x * x * y - 10 *
        x * x * y * y * y + py;
  end;
end;


function iterateJulia(px, py, ax, ay: real; m: integer): integer;
var
  x, y: real;
  xz: real;
  iterations: integer;

begin
  x := px;
  y := py;
  xz := 0;
  iterations := 0;
  while (((x * x + y * y) < (2 * 2)) and (iterations < m)) do
  begin
    xz := iterreal(2, x, y, ax);
    y := iterimg(2, x, y, ay);
    x := xz;
    iterations := iterations + 1;
  end;
  Result := iterations;
  iterateJulia := iterations;
end;


procedure colorize(inarr: vmap; aim: TBitmap; imax: integer);
var
  i, l: integer;
  col:integer;
begin
  for i := 0 to Length(inarr.val) - 1 do
  begin
    for l := 0 to Length(inarr.val[i]) - 1 do
    begin
      if inarr.val[i][l] < imax then
      begin
      //aim.canvas.Pixels[i, l] := RGBToColor(255, 255, 255)
        col := inarr.val[i][l];
         if not(inarr.cmin=inarr.cmax)then
          col := Math.floor(((col - inarr.cmin) / (inarr.cmax - inarr.cmin)) * 255)
          else
          col:=254;

          if col > 254 then
            col := 254;
          bmp.canvas.Pixels[i, l] := gradient[index][col];
      end
      else
      begin
        aim.canvas.Pixels[i, l] := RGBToColor(0, 0, 0);
      end;
    end;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i, l: integer;
  a, b, c, d: real;
begin

  r1 := v1;
  r2 := v2;

  r1 := rotateXY(r1, strToFloat(Edit1.Text));
  r1 := rotateXZ(r1, strToFloat(Edit2.Text));
  r1 := rotateXW(r1, strToFloat(Edit3.Text));
  r1 := rotateYZ(r1, strToFloat(Edit4.Text));
  r1 := rotateYW(r1, strToFloat(Edit5.Text));
  r1 := rotateZW(r1, strToFloat(Edit6.Text));

  r2 := rotateXY(r2, strToFloat(Edit1.Text));
  r2 := rotateXZ(r2, strToFloat(Edit2.Text));
  r2 := rotateXW(r2, strToFloat(Edit3.Text));
  r2 := rotateYZ(r2, strToFloat(Edit4.Text));
  r2 := rotateYW(r2, strToFloat(Edit5.Text));
  r2 := rotateZW(r2, strToFloat(Edit6.Text));

  r0.x := strToFloat(Edit7.Text);
  r0.y := strToFloat(Edit8.Text);
  r0.z := strToFloat(Edit9.Text);
  r0.w := strToFloat(Edit10.Text);


  zoom := strToFloat(Edit11.Text);
  maxiter:=strToInt(Edit12.Text);
  bmp.Width := Panel1.Width;
  bmp.Height := Panel1.Height;
  SetLength(values.val, bmp.Width);
  values.cmin:=maxiter;
  values.cmax:=0;
  for i := 0 to Length(values.val) - 1 do
  begin
    SetLength(values.val[i], bmp.Height);
    for l := 0 to Length(values.val[0]) - 1 do
    begin
      a := r0.x + (i / zoom+xoff) * r1.x + (l / zoom+yoff) * r2.x;
      b := r0.y + (i / zoom+xoff) * r1.y + (l / zoom+yoff) * r2.y;
      c := r0.z + (i / zoom+xoff) * r1.z + (l / zoom+yoff) * r2.z;
      d := r0.w + (i / zoom+xoff) * r1.w + (l / zoom+yoff) * r2.w;
      values.val[i][l] := iterateJulia(a, b, c, d, maxiter);
      if values.cmax<values.val[i][l] then
        values.cmax:=values.val[i][l];
      if values.cmin>values.val[i][l] then
        values.cmin:=values.val[i][l];
    end;
  end;
  colorize(values, bmp, maxiter);
  Panel1.Canvas.draw(0, 0, bmp);
  xoffalt:=xoff;
  yoffalt:=yoff;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  index:=Combobox1.ItemIndex;
end;


procedure TForm1.FormCreate(Sender: TObject);
var
   n1, i: integer;
  fnum: TStringList;
begin
  zoom := 500;
  xoff := -Math.floor(Panel1.Width / 2)/zoom;
  yoff := -Math.floor(Panel1.Height / 2)/zoom;
  xoffalt := xoff;
  yoffalt := yoff;
  v1.x := 1;
  v1.y := 0;
  v1.z := 0;
  v1.w := 0;

  v2.x := 0;
  v2.y := 1;
  v2.z := 0;
  v2.w := 0;
  bmp := TBitmap.Create;
  maxiter := 100;


  //gradientPic.LoadFromFile('gradient4.bmp');
  label1.Caption := 'Zoom: ' + IntToStr(trunc(zoom)) + '-fach';
  {Initalisieren der Farbskala}
  SetLength(gradient, 1);
  Combobox1.Clear;
  Combobox1.Items.Add('HSL Gradient');
  //Combobox1.ItemIndex:=0;
  index := 0;
  n1 := 0;
  while (n1 < 255) do
  begin
    gradient[0][n1] := HLStoColor(n1, 128, 200);       {Mit HSL}
    n1 := n1 + 1;
  end;


  fnum := findAllFiles('./Gradients');
  for i := 0 to fnum.Count - 1 do
  begin
    SetLength(gradient, Length(gradient) + 1);
    gradientPic := Tbitmap.Create;
    gradientPic.LoadFromFile(fnum.Strings[i]);
    Combobox1.Items.Add('Gradient ' + IntToStr(i + 1));
    n1 := 0;
    while (n1 < 255) do
    begin
      gradient[i + 1][n1] := gradientPic.canvas.Pixels[n1, 0];{Mit einer bmp Datei}
      //gradient[n1] := HLStoColor(n1, 128, 200);       {Mit HSL}
      n1 := n1 + 1;
    end;
    gradientPic.Clear();
  end;
end;

procedure TForm1.Panel1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if (Button = mbLeft) then
  begin
    xoff := xoffalt + real((X-(Panel1.Width/2))/zoom);
    yoff := yoffalt + real((Y-(Panel1.Height/2))/zoom);
  end;
end;

end.
