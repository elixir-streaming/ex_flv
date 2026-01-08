defmodule ExFLV.Tag.ExAudioDataTest do
  use ExUnit.Case, async: true

  doctest ExFLV.Tag.ExAudioData

  alias ExFLV.Tag.{ExAudioData, Serializer}

  describe "serialize/1" do
    setup do
      audio_data = %ExFLV.Tag.ExAudioData{
        packet_type: :multi_channel_config,
        codec_id: :flac,
        channel_order: :native,
        channel_count: 2,
        channels: [:front_left, :front_right],
        data: <<>>
      }

      {:ok, audio_data: audio_data}
    end

    test "serialize", %{audio_data: audio_data} do
      serialized = Serializer.serialize(audio_data)

      assert IO.iodata_to_binary(serialized) ==
               <<148, 102, 76, 97, 67, 1, 2, 0, 0, 0, 3>>
    end

    test "serialize and parse", %{audio_data: audio_data} do
      serialized = Serializer.serialize(audio_data)
      binary = IO.iodata_to_binary(serialized)

      {:ok, parsed} = ExAudioData.parse(binary)
      assert parsed == audio_data

      audio_data = %ExAudioData{
        packet_type: :coded_frames,
        codec_id: :mp3,
        data: <<1, 2, 3, 4, 5>>
      }

      serialized = Serializer.serialize(audio_data)
      {:ok, parsed} = ExAudioData.parse(IO.iodata_to_binary(serialized))
      assert parsed == audio_data

      audio_data = %ExAudioData{
        packet_type: :multi_channel_config,
        codec_id: :flac,
        channel_order: :custom,
        channel_count: 4,
        channels: [:front_left, :front_right, :back_left, :back_right],
        data: <<>>
      }

      serialized = Serializer.serialize(audio_data)
      {:ok, parsed} = ExAudioData.parse(IO.iodata_to_binary(serialized))
      assert parsed == audio_data
    end
  end
end
