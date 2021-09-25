from chroma import rgbx, darken, Color
from pixie import Image, readImage, autoStraightAlpha, writeFile
from os import splitFile, `/`, changeFileExt
import cligen

proc themain(darkenedTo: float32, input: string, output = "") =
  var img = readImage input
  for colordata in img.data.mitems:
    let thergba = autoStraightAlpha colordata
    let color = Color(
      r: float32(thergba.r) / 255.0,
      g: float32(thergba.g) / 255.0,
      b: float32(thergba.b) / 255.0,
      a: float32(thergba.a) / 255.0,
    )
    let newc = color.darken 0.2
    colordata = rgbx(uint8(newc.r * 255.0), uint8(newc.g * 255.0),
                     uint8(newc.b * 255.0), uint8(newc.a * 255.0))
    var fname = output
    if fname == "":
      let (dir, f, ext) = splitFile input
      fname = dir / (f & "-darkened").changeFileExt(ext)
    img.writeFile(fname)

dispatch(themain)
