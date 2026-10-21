## 0.1.0

- Initial version: schema-less protobuf wire format `PbMessage` model,
  `pb_reader.dart` (`pbDecodeMessage`, typed getters, `pbGuessBytesKind`,
  `pbMessageToText` like `protoc --decode_raw`) not linking
  `pb_writer.dart` (`pbEncodeMessage`), exact 64-bit values on every
  platform, the `pb_dump` binary and the `tekartik-app-pb-codec` agent skill.
