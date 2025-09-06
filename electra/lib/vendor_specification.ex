defmodule VendorSpecification do
  defstruct [:name, :maxoffset, :rps]

  def new(name, maxoffset, rps) do
    %VendorSpecification{
      name: name,
      maxoffset: maxoffset,
      rps: rps
    }
  end
end
