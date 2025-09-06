defmodule VendorProcess do

  def start(vendor_spec, vendor_pid, time, electra_pid) do
    spawn(fn ->
      vendor_process(vendor_spec, vendor_pid, time, electra_pid)
    end)
  end

  def vendor_process(vendor_spec, vendor_pid, time, electra_pid) do
    send(vendor_pid, {:get_sensor_count, self()})

    receive do
      {:get_sensor_count, sensor_count} ->
        IO.puts("vendor  ::  #{vendor_spec.name} has #{sensor_count} sensors")

        all_sensor_data = get_all_sensor_data(vendor_spec, vendor_pid, time, sensor_count)

        if length(all_sensor_data) == sensor_count do

          store_data_in_dets(all_sensor_data, vendor_spec.name, time)
          avg_result = calculate_simple_average(all_sensor_data)

          if avg_result != nil do
            {avg_p, avg_v, avg_c} = avg_result
            send(electra_pid, {:vendor_data, vendor_spec.name, avg_p, avg_v, avg_c})
          else
            send(electra_pid, {:listen_for_data_loss, vendor_spec.name})
          end
        else
          IO.puts("count mismatch, data losss :  #{vendor_spec.name}: expected #{sensor_count} , got here only #{length(all_sensor_data)}")
          send(electra_pid, {:listen_for_data_loss, vendor_spec.name})
        end

      _ ->
        send(electra_pid, {:listen_for_data_loss, vendor_spec.name})
    after
      1000 ->
        send(electra_pid, {:listen_for_data_loss, vendor_spec.name})
    end
  end








  def get_all_sensor_data(vendor_spec, vendor_pid, time, sensor_count) do
    all_data = []
    current_start = 1

    get_data_loop(vendor_spec, vendor_pid, time, current_start, sensor_count, all_data)
  end




  def get_data_loop(vendor_spec, vendor_pid, time, current_start, sensor_count, collected_data) do
    if current_start > sensor_count do
      List.flatten(collected_data)
    else

      remaining_sensors = sensor_count - current_start + 1
      offset = if remaining_sensors >= vendor_spec.maxoffset do
        vendor_spec.maxoffset
      else
        remaining_sensors
      end

      send(vendor_pid, {:get_sensor_data, time, current_start, offset, self()})

      receive do
        {:get_sensor_data, sensor_data_list} ->
          new_collected_data = [sensor_data_list | collected_data]
          next_start = current_start + offset
          get_data_loop(vendor_spec, vendor_pid, time, next_start, sensor_count, new_collected_data)
        _ ->
          IO.puts("ffailed for request  for :: #{vendor_spec.name} ,, start idx #{current_start}")
          List.flatten(collected_data)
      after
        900 ->
          IO.puts("timeout didn't get data::  #{vendor_spec.name} , start idx #{current_start}")
          List.flatten(collected_data)
      end
    end
  end







#  noot use case in happy flow
  def store_data_in_dets(sensor_data_list, vendor_name, time) do
    for sensor_data <- sensor_data_list do
      :dets.insert(:sensor_storage, {
        vendor_name,
        sensor_data.id,
        time,
        sensor_data.p,
        sensor_data.v,
        sensor_data.c
      })
    end
  end








  def calculate_simple_average(sensor_data_list) do

    if length(sensor_data_list) == 0 do
      nil
    else


      all_p_values = for sensor <- sensor_data_list, do: sensor.p
      all_v_values = for sensor <- sensor_data_list, do: sensor.v
      all_c_values = for sensor <- sensor_data_list, do: sensor.c

      final_p = Enum.sum(all_p_values)
      final_v = Enum.sum(all_v_values)
      final_c = Enum.sum(all_c_values)
      count = length(sensor_data_list)

      avg_p = final_p / count
      avg_v = final_v / count
      avg_c = final_c / count

      {avg_p, avg_v, avg_c}
    end
  end
end
