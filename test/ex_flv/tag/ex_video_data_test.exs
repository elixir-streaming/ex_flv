defmodule ExFLV.Tag.ExVideoDataTest do
  use ExUnit.Case, async: true

  alias ExFLV.Tag.{ExVideoData, Serializer}

  doctest ExFLV.Tag.ExVideoData

  describe "parse!/1" do
    test "raises for invalid binary" do
      assert_raise RuntimeError, "Failed to parse EXVIDEODATA: invalid_tag", fn ->
        ExVideoData.parse!(<<150, 97, 118, 48>>)
      end
    end
  end

  describe "serialize/1" do
    setup do
      video_data = %ExVideoData{
        frame_type: :interframe,
        packet_type: :coded_frames,
        codec_id: :h264,
        composition_time_offset: -10,
        data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>
      }

      {:ok, video_data: video_data}
    end

    test "Serialize", %{video_data: video_data} do
      serialized = Serializer.serialize(video_data)

      assert IO.iodata_to_binary(serialized) ==
               <<161, 97, 118, 99, 49, 255, 255, 246, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>
    end

    test "Serialize and Parse", %{video_data: video_data} do
      serialized = Serializer.serialize(video_data)
      binary = IO.iodata_to_binary(serialized)

      {:ok, parsed} = ExVideoData.parse(binary)
      assert parsed == video_data
    end
  end
end
