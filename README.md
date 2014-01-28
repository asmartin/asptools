# asptools

Tools for use with Aftershot Pro.

## asp2ps.sh

This script allows you to launch Photoshop as the external editor in Aftershot Pro on Linux.

### System Requirements
asp2ps.sh requires the installation of these packages: `lib32-lcms zenity wine`. It also requires that you install a licensed copy of AfterShot Pro on Linux and Adobe Photoshop (with Adobe Camera RAW) in WINE.

You must also configure the Y: drive in WINE to point to your Linux system root: `/`

### Installation
1. Copy asp2ps.sh somewhere on your PATH, e.g /usr/local/bin
2. Make sure asp2ps.sh is executable: `chmod +x /usr/local/bin/asp2ps.sh`
3. In AfterShot Pro, go to File - Preferences. Select "External Editor" and then click the "Choose..." button and select asp2ps.sh. For the "File Format" dropdown, select "Tiff (16-bit)". Click OK.
4. edit the following variables in asp2ps.sh, filling in the path to your WINE prefix where Photoshop is installed, the version of Photoshop that you are using, and the uppercase filetype extension of your RAW file (in this example it is Canon's CR2 format):

```bash
export WINEPREFIX=/home/yourusername/.wine
export PHOTOSHOP_VERSION=5.1
RAW_FILETYPE_UPPERCASE=CR2
```

### Usage
1. Edit a RAW file in AfterShot Pro and then right-click on it and select "Edit with asp2ps..."
2. In the selection box that appears, choose the format that you would like to use when importing the file into Photoshop:
    1. CR2 + XMP (default) - passes the RAW file and converts the AfterShot Pro XMP file to Adobe Camera RAW XMP*
    2. CR2 - passes the RAW file (with default settings) to Adobe Camera RAW
    3. TIFF - takes the exported TIFF from AfterShot Pro and opens it in Photoshop
3. Click OK; the image should open in Photoshop
4. If the image opens in Adobe Camera RAW, hold SHIFT when clicking the `Open Image` button to change it into `Open Object`, which will open the RAW file as a Smart Object in Photoshop. This allows you to return to Adobe Camera RAW after doing processing in Photoshop for additional RAW adjustments.

*Note that the RAW processing engines in AfterShot Pro and Adobe Camera RAW are different, so even though the values are converted and scaled for Adobe Camera RAW, the image will probably not look the same as it does in AfterShot Pro. However, by preserving the settings, you get a similar point of reference to keep editing the photo from.
