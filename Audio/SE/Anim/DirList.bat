echo off

cd %1

dir /a-h /b /-p /o:gen >filelisting.txt

filelisting.txt

cd ..

echo on