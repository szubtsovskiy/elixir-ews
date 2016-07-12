defmodule Events.EwsFetcher do
  require Record
  import Record, only: [defrecord: 3, extract: 2]

  defrecord :conversion_rate, :"P0:ConversionRate", extract(:"P0:ConversionRate", from: "include/CurrencyConvertor.asmx?WSDL.hrl")
  
end