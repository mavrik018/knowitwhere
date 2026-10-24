// Copies screenshots into an App Store-ready folder: same pixels, but with
// the alpha channel removed. App Store Connect rejects screenshots that have
// one, and Flutter's golden files are always RGBA.
//
// Usage: swift tool/screenshots/flatten_for_app_store.swift <in.png>... <out-dir>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
  FileHandle.standardError.write("usage: flatten_for_app_store.swift <in.png>... <out-dir>\n".data(using: .utf8)!)
  exit(2)
}
let outDir = URL(fileURLWithPath: args.last!, isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for path in args.dropLast() {
  let input = URL(fileURLWithPath: path)
  guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
    let context = CGContext(
      data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
  else {
    FileHandle.standardError.write("cannot read \(path)\n".data(using: .utf8)!)
    exit(1)
  }
  // Anything transparent lands on white rather than black.
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

  let output = outDir.appendingPathComponent(input.lastPathComponent)
  guard let flat = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
  else { exit(1) }
  CGImageDestinationAddImage(destination, flat, nil)
  guard CGImageDestinationFinalize(destination) else { exit(1) }
  print("\(output.path)  \(image.width)×\(image.height)")
}
