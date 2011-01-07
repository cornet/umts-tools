@echo off
cls
echo This program will install the Perl modules required to run
echo umts-tools.
echo.
echo IMPORTANT : you need to make sure that Perl is installed on your
echo computer before running this installer. You can download a good
echo distribution of Perl from http://www.activestate.com/
echo.
set choice=
set /P choice="Type Q to quit, or ENTER to continue : " 
if not "%choice%"=="" (
  echo Aborting.
  goto END
)

echo.
echo If you access internet via a proxy, please enter it below in the
echo form http://myuser:mypass@proxy.mydomain.org:80/, otherwise just
echo press ENTER.
echo.
set /P HTTP_PROXY="Proxy server : "

echo.
echo Installing Perl modules..
call ppm install Win32-API
call ppm install Config-General
call ppm install Digest-HMAC
call ppm install http://www.bribes.org/perl/ppm/Win32-SerialPort.ppd
call ppm install http://theoryx5.uwinnipeg.ca/ppms/Crypt-Rijndael.ppd
call ppm install File-Type
call ppm install XML-Simple

:END

