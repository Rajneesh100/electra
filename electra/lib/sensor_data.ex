defmodule SensorData do
  defstruct [:time, :id, :p, :v, :c]

  def new(time, id, p, v, c) do
    %SensorData{
      time: time,
      id: id,
      p: p,
      v: v,
      c: c
    }
  end
end
