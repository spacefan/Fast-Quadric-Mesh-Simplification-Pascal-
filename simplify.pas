program simplify;
//Example program to simplify meshes
// https://github.com/neurolabusc/Fast-Quadric-Mesh-Simplification-Pascal-
//To compile
// fpc -O3 -XX -Xs simplify.pas
//On OSX to explicitly compile as 64-bit
// ppcx64  -O3 -XX -Xs simplify.pas
//With Delphi
// >C:\PROGRA~2\BORLAND\DELPHI7\BIN\dcc32 -CC -B  simplify.pas
//To execute
// ./simplify bunny.obj out.obj 0.2

{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}
uses
 {$IFDEF FPC} mz3,  {$IFNDEF DARWIN}DateUtils, {$ENDIF}{$ELSE} Windows, {$ENDIF}
 Classes, meshify_simplify_quadric, obj, sysutils;

procedure ShowHelp;
begin
  {$IFDEF FPC}
	writeln('Usage: '+paramstr(0)+' <input> <output> <ratio> <agressiveness)');
	writeln(' Input: name of existing MZ3 or OBJ format mesh');
 	writeln(' Output: name for decimated MZ3 or OBJ format mesh');
 	writeln(' Ratio: (default = 0.2) for example 0.1 will decimate 90% of triangles');
 	writeln(' Agressiveness: (default = 2.0) faster (9) or better decimation (1)');
 	writeln('Notes:');
 	writeln(' The OBJ format is popular and useful for sharing files');
 	writeln(' The MZ3 format is creates more compact files');
	writeln('Examples:');
	{$IFDEF UNIX}
	writeln(' '+paramstr(0)+' ~/dir/in.mz3 ~/dir/out.mz3 0.2');
	writeln(' '+paramstr(0)+' ~/dir/bunny.obj ~/dir/out.obj 0.2');
	writeln(' '+paramstr(0)+' ~/dir/bunny.obj ~/dir/out.mz3 0.2');
	{$ELSE}
	writeln(' '+paramstr(0)+' c:\dir\in.mz3 c:\dir\out.mz3 0.2');
	writeln(' '+paramstr(0)+' c:\dir\bunny.obj c:\dir\out.obj 0.2');
	writeln(' '+paramstr(0)+' c:\dir\bunny.obj c:\dir\out.mz3 0.2');
	{$ENDIF}
  {$ELSE} //if FPC else Delphi - Delphi does not support ZStreams
    writeln('Usage: '+paramstr(0)+' <input> <output> <ratio> <agressiveness)');
    writeln(' Input: name of existing OBJ format mesh');
    writeln(' Output: name for decimated OBJ format mesh');
    writeln(' Ratio: (default = 0.2) for example 0.1 will decimate 90% of triangles');
    writeln(' Agressiveness: (default = 2.0) faster (9) or better decimation (1)');
    writeln('Example:');
    writeln(' '+paramstr(0)+' c:\dir\bunny.obj c:\dir\out.obj 0.2');
  {$ENDIF}
end;

procedure printf(s: string); //for GUI applications, this would call showmessage or memo1.lines.add
begin
     writeln(s);
end;

{$IFDEF FPC}
function isMz3(filename: string): boolean;
begin
	result := upcase(ExtractFileExt(filename)) = '.MZ3';
end;
{$ENDIF}

procedure DecimateMesh(inname, outname: string; ratio, agress: single);
var
  targetTri, startTri: integer;
  faces: TFaces;
  vertices: TVertices;
    {$IFDEF FPC} {$IFDEF DARWIN} msec: qWord;{$ELSE} msec: Int64; tic :TDateTime; {$ENDIF} {$ELSE} msec: dWord; {$ENDIF}
begin
  {$IFDEF FPC}
  if isMz3(inname) then
  	LoadMz3(inname, faces, vertices)
  else
  {$ENDIF}
    LoadObj(inname, faces, vertices);
  printf(format(' simplifying %s with a ratio of %.2f and agressiveness of %.2f', [inname, ratio, agress ]));
  startTri := length(faces);
  targetTri := round(length(faces) * ratio);
  if (targetTri < 0) or (length(faces) < 1) or (length(vertices) < 3) then begin
     printf('Unable to load the mesh');
     exit;
  end;
  {$IFDEF FPC} {$IFDEF DARWIN} msec := GetTickCount64(); {$ELSE}tic := Now();{$ENDIF} {$ELSE} msec := GetTickCount();{$ENDIF}
  simplify_mesh(faces, vertices, targetTri, agress);
  {$IFDEF FPC} {$IFDEF DARWIN} msec := GetTickCount64()-msec; {$ELSE}msec := MilliSecondsBetween(Now(),tic);{$ENDIF} {$ELSE} msec := GetTickCount() - msec; {$ENDIF}
  printf(format(' number of triangles reduced from %d to %d (%.3f, %.2fsec)', [startTri, length(Faces), length(Faces)/startTri, msec*0.001  ]));
  if length(outname) > 0 then begin
  	printf('  Creating file '+ outname);
  	{$IFDEF FPC}
        if isMz3(outname) then
  	  SaveMz3(outname, faces, vertices)
  	else
        {$ENDIF}
  	  SaveObj(outname, faces, vertices);
  end;
  setlength(faces,0);
  setlength(vertices,0);
end;

procedure ParseCmds;
var
	inname, outname: string;
	ratio, agress: single;
begin
	printf('Mesh Simplification (C)2014 by Sven Forstmann, MIT License '+{$IFDEF CPU64}'64-bit'{$ELSE}'32-bit'{$ENDIF});
	if ParamCount < 1 then begin
  		ShowHelp;
  		exit;
  	end;
  	inname := paramstr(1);
  	if ParamCount < 2 then begin
                {$IFDEF FPC}
                outname := ChangeFileExt(inname, '_simple.mz3');
                {$ELSE}
                outname := ChangeFileExt(inname, '_simple.obj');
                {$ENDIF}
  	end else
  		outname := paramstr(2);
  	ratio := 0.2;
  	if ParamCount > 2 then
  		ratio := StrToFloatDef(paramstr(3),0.5);
  	if (ratio <= 0.0) or (ratio >= 1.0) then begin
  		printf('Ratio must be more than zero and less than one.');
  		exit;
  	end;
  	agress := 2.0;
  	if ParamCount > 2 then
  		agress := StrToFloatDef(paramstr(4),2.0);
	DecimateMesh(inname, outname, ratio, agress);
end;

begin
	ParseCmds;
end.
