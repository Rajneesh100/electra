defmodule Electra do
  use Application

  def start(_type, _args) do
    :dets.open_file(:sensor_storage, [type: :bag])   # store  the data // need to fix this for failure use case

    run_multiple_times(1)

    {:ok, self()}
  end

  def stop(_state) do
    :dets.close(:sensor_storage)
    :ok
  end

  def process_lfa_time(time) do
    IO.puts("====================================lfa for time #{time} ===========================================")
    vendors = VendorList.get_vendors()
    IO.inspect(vendors)

    vendor_pid = VendorSimulation.start()


    vendor_processes = for vendor <- vendors do
      process_pid = VendorProcess.start(vendor, vendor_pid, time, self())
      IO.puts("vendor thread started :: #{vendor.name}")
      process_pid
    end

    vendor_results = []
    wait_for_all_vendors(vendors, vendor_results, 0)
  end






  def wait_for_all_vendors(vendors, results, completed_count) do
    total_vendors = length(vendors)

    # // sab kuch aa jaye then avg
    if completed_count >= total_vendors do
      IO.puts("data collection done . calculate final averages:: ")
      calculate_and_show_final_average(results)




    else
      receive do
        {:vendor_data, vendor_name, avg_p, avg_v, avg_c} ->
          IO.puts("avg data from  #{vendor_name}: p=#{avg_p},v=#{avg_v },  curr=#{avg_c}")
          new_results = [{vendor_name, avg_p, avg_v, avg_c} | results]
          wait_for_all_vendors(vendors, new_results, completed_count + 1)

        {:listen_for_data_loss, vendor_name} ->
          IO.puts("lfa not completed, data loss  for : #{vendor_name}")
          wait_for_all_vendors(vendors, results, completed_count + 1)

      after
        1000 ->
          IO.puts("wait timeout for vendors data didn't receved")
          # calculate_and_show_final_average(results)
      end
    end
  end

  def calculate_and_show_final_average(vendor_results) do
    if length(vendor_results) == 0 do
      IO.puts("No vendor data received!")
    else

      all_p_values = for {_name, p, _v, _c} <- vendor_results, do: p
      all_v_values = for {_name, _p, v, _c} <- vendor_results, do: v
      all_c_values = for {_name, _p, _v, c} <- vendor_results, do: c

      final_p = Enum.sum(all_p_values)
      final_v = Enum.sum(all_v_values)
      final_c = Enum.sum(all_c_values)

      count = length(vendor_results)

      if count > 0 do
        final_avg_p = final_p / count
        final_avg_v = final_v / count
        final_avg_c = final_c / count

        IO.puts("lfa done:: ")
        IO.puts(" average p: #{final_avg_p}")
        IO.puts("average v: #{final_avg_v}")
        IO.puts("aerage c: #{final_avg_c}")
        IO.puts("vendor counts:  #{count}")
      else
        IO.puts("zero vendors")
      end
    end
  end

  # Simple function to run multiple times
  def run_multiple_times(time) do
      process_lfa_time(time)
      :timer.sleep(1000)
      run_multiple_times(time+1)

  end
end
