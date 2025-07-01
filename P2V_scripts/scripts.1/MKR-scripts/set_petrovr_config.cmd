
echo setting directories read-only

set dira="C:\ProgramData\Aucerna\PetroVR\Model Library\Economics\Models"
echo "%dira%"
attrib -r  "%dira%" /S /D

set dira="C:\ProgramData\Aucerna\PetroVR\Model Library\Economics\Globals\PVR Globals.glb"
echo "%dira%"
attrib -r  "%dira%" /S /D

set dira="C:\ProgramData\Aucerna\PetroVR\Images"
echo "%dira%"
attrib -r  "%dira%" /S /D

set dira="C:\ProgramData\Aucerna\PetroVR\Catalogs"
echo "%dira%"
attrib -r  "%dira%" /S /D


pause