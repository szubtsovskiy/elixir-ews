defmodule Events.Ews do

  # "https://mail.derivco.co.uk/EWS/Exchange.asmx"

  def get_calendar(endpoint, user, password) do
    credentials = Base.encode64("#{user}:#{password}")
    HTTPoison.post!(endpoint, get_calendar_body, %{"Authorization" => "Basic #{credentials}", "Content-Type" => "text/xml"})
  end

  defp get_calendar_body do
    """
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages">
        <soap:Header>
            <t:RequestServerVersion Version="Exchange2010"/>
        </soap:Header>
        <soap:Body>
            <GetFolder xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
                <FolderShape>
                    <t:BaseShape>Default</t:BaseShape>
                </FolderShape>
                <m:FolderIds>
                    <t:DistinguishedFolderId Id="calendar"/>
                </m:FolderIds>
            </GetFolder>
        </soap:Body>
    </soap:Envelope>
    """
  end

end