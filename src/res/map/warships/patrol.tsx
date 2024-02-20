<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="patrol" tilewidth="8" tileheight="8" tilecount="6" columns="2">
 <image source="patrol.png" width="16" height="24"/>
 <tile id="0">
  <properties>
   <property name="damaged_offset" type="int" value="2"/>
  </properties>
  <objectgroup draworder="index" id="2">
   <object id="1" type="CollisionShape" x="1" y="4" width="7" height="4"/>
  </objectgroup>
 </tile>
 <tile id="1">
  <properties>
   <property name="damaged_offset" type="int" value="2"/>
  </properties>
  <objectgroup draworder="index" id="2">
   <object id="1" type="CollisionShape" x="0" y="3" width="7" height="5"/>
  </objectgroup>
 </tile>
 <tile id="2">
  <properties>
   <property name="damaged_offset" type="int" value="2"/>
  </properties>
 </tile>
 <tile id="3">
  <properties>
   <property name="damaged_offset" type="int" value="2"/>
  </properties>
 </tile>
 <tile id="4">
  <properties>
   <property name="damaged_offset" type="int" value="0"/>
  </properties>
 </tile>
 <tile id="5">
  <properties>
   <property name="damaged_offset" type="int" value="0"/>
  </properties>
 </tile>
</tileset>
