-module('CurrencyConvertor.asmx?WSDL_client_test').
-compile(export_all).

-include("CurrencyConvertor.asmx?WSDL.hrl").


'ConversionRate'() -> 
    'CurrencyConvertor.asmx?WSDL_client':'ConversionRate'(
        #'P0:ConversionRate'{
            'FromCurrency' = "?",
            'ToCurrency' = "?"},
    _Soap_headers = [],
    _Soap_options = [{url,"http://www.webservicex.net/CurrencyConvertor.asmx"}]).

