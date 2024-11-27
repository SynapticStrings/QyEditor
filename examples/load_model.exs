defmodule Qixuan_V2_5_0 do
  @doc """
  Model info.
  """
  @meta %{
    name: "绮萱",
    version: "v2.5.0",
    author: "DiffSinger Community",
    author_link: "https://github.com/openvpi/DiffSinger"
  }

  def import_meta(), do: @meta |> IO.inspect(); nil
end

## Temporary
model_root_path = "priv/Qixuan_v2.5.0_DiffSinger_OpenUtau"
model_path = fn sub -> Path.join(model_root_path, sub) end
# Variance Model
# pitch_predict_path = model_path.("")
_linguisitic_path = model_path.("dsvariance/0816_qixuan_multilingual_multivar.qixuan.linguistic.onnx")
_variance_path = model_path.("dsvariance/0816_qixuan_multilingual_multivar.qixuan.variance.onnx")
# Acostic Model
acostic_model_path = model_path.("0816_qixuan_multilingual_acoustic.qixuan.onnx")
# Vocoder
_vocoder_path = model_path.("dsvocoder/nsf_hifigan_qixuan_004.onnx")

acostic_model = Ortex.load(acostic_model_path) |> IO.inspect()
