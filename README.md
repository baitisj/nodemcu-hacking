# nodemcu-hacking
My ESP8266 nodemcu hacking project. Of particular interest:
  * **morse.lua** and **morse_table.lua** - components that can blink out morse code through a GPIO. Implemented in callbacks, should be very low-power-friendly.
  * **ringbuffer.lua** - simple implementation of a ring buffer in Lua
  * **dump_to_serial.py** - hacked version of luatool that sends a file to the system as though you were typing it
