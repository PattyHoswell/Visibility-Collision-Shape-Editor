# Visibility Collision Shape Editor
 Show/Hide visibility of collision shape in the editor (Also works by layers)

https://github.com/user-attachments/assets/33b18a0c-5c82-4219-b698-98ce8ceb18c4

You can disable by local or instanced scenes. Local means they are from that scenes while instanced means they are from another scene added into that scenes.

This will override any individual visibility you made on the collision shape.

Disabling by layer only hides them if all layer is disabled, if for example a collision has layer of 1 and 2 and you disabled only layer 1 then it will still visible on the editor unless you disabled both layer

TileMapLayer is not included as you can just set that on the TileMapLayers itself (but if you do need it to be included feel free to make a request and i'll consider it)

It also works for 3D (Thanks to lagmeister for testing it) but I don't know enough about 3D setup to provide a good demonstration, if it doesn't you can provide the scene so I can take a look at it myself.

The plugin will save your config from previous changes. It uses separate thread for saving the file so it won't freeze the editor but if it doesn't work as intended somehow then you can set the `threaded` parameter to false on the code for saving.

### Note: This only changes their visibility in the editor, it won't affect their functionality in game
