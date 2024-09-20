# ColdWar

This is the code from Enigma's Cold War Server version 2.4 (aka ECW V2). This is being shared publicly to help the DCS community create their own servers. 

While this is being shared for people to use, we really recommend people to try to push the boudnaries. Retracing the same line can get boring and DCS needs to be shaken up to be interesting. 

This ReadMe will be updated when questions start to come in and I can answer them both on discord and in here. You can ask your questions on discord in the #scripting-hell channel. https://discord.gg/enigma89

Code Breakdown:

.startInit - This file when true tells the campaign system that it is a new campaign. When false it will load from the persistence files (files/persistence)

Core/Variables.lua - This is the 'admin panel' where game mastesr can control values
