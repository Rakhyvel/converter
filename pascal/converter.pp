// To run: fpc -Mdelphi converter.pp && ./converter ../input.md
// Pros:
// Cons:
//  - Case insensitive
//  - I don't think you can define variables in the middle of code
//  - Don't like that #13#10 is the newline character. Give me escape characters!

program ReadFile;
uses
 Sysutils;

const
  C_FNAME = '../input.md';

var
  tfIn: TextFile;
  contents: string = '';
  s: string;

begin
  // Open input file, read contents of file
  AssignFile(tfIn, C_FNAME);
  try 
    reset(tfIn);
    while not eof(tfIn) do
    begin
      readln(tfIn, s);
      contents := contents + #13#10 + s;
    end;
  except
    on E: EInOutError do
     Writeln('File handling error occurred. Details: ', E.Message);
  end;
  CloseFile(tfIn);
  writeln(contents);

  // Create parser, parse document

  // Write out document
end.