defmodule VendorSimulation do

  def start do
    spawn(fn -> listen_loop() end)
  end

  def listen_loop do
    receive do
      {:get_sensor_count, send_me_at_my_pid} ->
        send(send_me_at_my_pid, {:get_sensor_count, 30})
        listen_loop()

      {:get_sensor_data, time, start, offset, send_me_at_my_pid} ->
        response_list = generate_sensor_data(time, start, offset)
        send(send_me_at_my_pid, {:get_sensor_data, response_list})
        listen_loop()

      _ ->
        listen_loop()
    end
  end

  defp generate_sensor_data(time, start, offset) do
    for i <- start..(start + offset - 1) do
      if i == 500 do # to simulate failue put any number between 1 to 50
        nil
      else
        SensorData.new(
          time,
          i,
          random_num(10, 20),
          random_num(10, 20),
          random_num(10, 20)
        )
      end
    end
    |> Enum.filter(fn x -> x != nil end)  # nil remove


  end






  defp random_num(min, max) do
    :rand.uniform(max - min + 1) + min - 1
  end
end
