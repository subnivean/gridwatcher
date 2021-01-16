This program makes heavy use of https://github.com/thorsten-gehrig/alexa-remote-control, found here under `~/github`, with some minor modifications.

`alexa-remote-control` requires `sudo install jq` for command-line parsing of JSON output.

Getting and saving required cookies was the hardest part. Lots of good advice at https://www.codementor.io/@slavko/controlling-amazon-echo-dot-with-shell-a-bit-of-fun-mz6xxz92n.

Note that in order to get the cookies required by the above onto my RPi, I had to:

```
sudo apt install vnc4server
sudo apt install lxsession
sudo apt install firefox-esr
```

After installation of the above, I needed to do a `sudo raspi-config` to enable VNC through the `Interfaces` menu item.

I also needed to `sudo apt install realvnc-vnc-viewer` onto my Ubuntu laptop, as `remmina` did not work.

Logged in to the Pi desktop via `vncviewer 192.168.1.6` from the laptop ('pi'/'B3st')

Once I got to a desktop on the Pi, I started Firefox and installed the `Export Cookies` add-on, after which I went to `https:\\alexa.amazon.com` and exported cookies in the `amazon.com` domain (clear all cookies first). This file was eventually saved to the `~/.alexa-remote-control/.alexa.cookies` file for Capcha-free logins through `cURL` and `wget`.