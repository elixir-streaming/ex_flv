defmodule ExFLV.Tag.ExVideoData do
  @moduledoc """
  Module describing an FLV enhanced video data tag.
  """

  alias ExFLV.Tag.VideoData

  @compile {:inline, packet_type: 1, frame_type: 1}

  @type packet_type ::
          :sequence_start
          | :coded_frames
          | :sequence_end
          | :coded_frames_x
          | :metadata
          | :mpeg2_ts_sequence_start
          | :multi_track
          | :mod_ex

  @type fourcc :: :avc1 | :hvc1 | :vp08 | :vp09 | :av01

  @type t :: %__MODULE__{
          frame_type: VideoData.frame_type(),
          packet_type: packet_type(),
          composition_time_offset: integer(),
          fourcc: fourcc(),
          data: iodata()
        }

  defstruct [:frame_type, :packet_type, :fourcc, :composition_time_offset, :data]

  @doc """
  Parses the binary into an `ExVideoTag` tag.

      iex> ExFLV.Tag.ExVideoData.parse(<<144, 104, 118, 99, 49, 1, 2, 3, 4, 5>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :keyframe,
        packet_type: :sequence_start,
        fourcc: :hvc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4, 5>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<161, 97, 118, 99, 49, 255, 255, 246, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :interframe,
        packet_type: :coded_frames,
        fourcc: :avc1,
        composition_time_offset: -10,
        data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<163, 97, 118, 99, 49, 1, 2, 3, 4>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :interframe,
        packet_type: :coded_frames_x,
        fourcc: :avc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<150, 97, 118, 48>>)
      {:error, :invalid_tag}

      iex> ExFLV.Tag.ExVideoData.parse(<<150, 97, 118, 48, 49>>)
      {:error, :invalid_tag}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_tag}
  def parse(<<1::1, frame_type::3, packet_type::4, fourcc::binary-size(4), data::binary>>)
      when frame_type in 1..5 and packet_type in 0..7 and packet_type != 6 do
    packet_type = packet_type(packet_type)
    fourcc = String.to_existing_atom(fourcc)
    {composition_time_offset, data} = parse_body(packet_type, fourcc, data)

    {:ok,
     %__MODULE__{
       frame_type: frame_type(frame_type),
       fourcc: fourcc,
       composition_time_offset: composition_time_offset,
       packet_type: packet_type,
       data: data
     }}
  end

  def parse(_), do: {:error, :invalid_tag}

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.ExVideoData.parse!(<<144, 104, 118, 99, 49, 1, 2, 3, 4, 5>>)
      %ExFLV.Tag.ExVideoData{
        frame_type: :keyframe,
        packet_type: :sequence_start,
        fourcc: :hvc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4, 5>>
      }
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse EXVIDEODATA: #{reason}"
    end
  end

  defp parse_body(:coded_frames, fourcc, <<composition_time_offset::24-signed, data::binary>>)
       when fourcc in [:avc1, :hvc1],
       do: {composition_time_offset, data}

  defp parse_body(_packet_type, _fourcc, data), do: {0, data}

  defp packet_type(0), do: :sequence_start
  defp packet_type(1), do: :coded_frames
  defp packet_type(2), do: :sequence_end
  defp packet_type(3), do: :coded_frames_x
  defp packet_type(4), do: :metadata
  defp packet_type(5), do: :mpeg2_ts_sequence_start
  defp packet_type(6), do: :multi_track
  defp packet_type(7), do: :mod_ex

  defp frame_type(1), do: :keyframe
  defp frame_type(2), do: :interframe
  defp frame_type(3), do: :disposable_interframe
  defp frame_type(4), do: :generated_keyframe
  defp frame_type(5), do: :command_frame

  defimpl ExFLV.Tag.Serializer do
    @compile {:inline, frame_type: 1, packet_type: 1}

    def serialize(video_data) do
      composition_time =
        case video_data.packet_type do
          :coded_frames -> <<video_data.composition_time_offset::24-signed>>
          _ -> <<>>
        end

      [
        <<1::1, frame_type(video_data.frame_type)::3, packet_type(video_data.packet_type)::4,
          to_string(video_data.fourcc)::binary-size(4), composition_time::binary>>,
        video_data.data
      ]
    end

    defp frame_type(:keyframe), do: 1
    defp frame_type(:interframe), do: 2
    defp frame_type(:disposable_interframe), do: 3
    defp frame_type(:generated_keyframe), do: 4
    defp frame_type(:command_frame), do: 5

    defp packet_type(:sequence_start), do: 0
    defp packet_type(:coded_frames), do: 1
    defp packet_type(:sequence_end), do: 2
    defp packet_type(:coded_frames_x), do: 3
    defp packet_type(:metadata), do: 4
    defp packet_type(:mpeg2_ts_sequence_start), do: 5
    defp packet_type(:multi_track), do: 6
    defp packet_type(:mod_ex), do: 7
  end
end
