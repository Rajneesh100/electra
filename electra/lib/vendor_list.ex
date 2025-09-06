defmodule VendorList do
  def get_vendors do
    [
      VendorSpecification.new("v1", 5, 5),
      VendorSpecification.new("v2", 6, 4)
    ]
  end
end
