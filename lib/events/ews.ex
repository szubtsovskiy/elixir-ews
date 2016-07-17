defmodule Events.Ews do

  # "https://mail.derivco.co.uk/EWS/Exchange.asmx"

  def get_calendar_events(endpoint, user, password) do
    credentials = {endpoint, user, password}
    get_folder(:calendar, credentials)
      |> find_items(credentials)
  end

  # PRIVATE API

  defp get_folder(folder_id, {endpoint, user, password}) do
    encoded_credentials = Base.encode64("#{user}:#{password}")
    req_body = get_folder_request(folder_id)
    req_headers = %{"Authorization" => "Basic #{encoded_credentials}", "Content-Type" => "text/xml"}
    case HTTPoison.post(endpoint, req_body, req_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with doc = Exml.parse(body),
             id = Exml.get(doc, "//t:CalendarFolder/t:FolderId/@Id") do
          {:ok, {id}}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp find_items({:ok, {id}} = _folder, {endpoint, user, password}) do
    encoded_credentials = Base.encode64("#{user}:#{password}")
    req_body = find_item_request({id})
    req_headers = %{"Authorization" => "Basic #{encoded_credentials}", "Content-Type" => "text/xml"}
    case HTTPoison.post(endpoint, req_body, req_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with doc = Exml.parse(body) do
          items = for id <- Exml.get(doc, "//t:CalendarItem/t:ItemId/@Id"), into: [] do
            %{"id" => id,
              "subject" => Exml.get(doc, "//t:CalendarItem[t:ItemId/@Id='#{id}']/t:Subject"),
              "start" => Exml.get(doc, "//t:CalendarItem[t:ItemId/@Id='#{id}']/t:Start"),
              "end" => Exml.get(doc, "//t:CalendarItem[t:ItemId/@Id='#{id}']/t:End"),
              "location" => Exml.get(doc, "//t:CalendarItem[t:ItemId/@Id='#{id}']/t:Location"),
              "organizer" => Exml.get(doc, "//t:CalendarItem[t:ItemId/@Id='#{id}']/t:Organizer/t:Mailbox/t:Name")}
          end
          {:ok, items}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp get_folder_request(folder_id) do
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
                    <t:DistinguishedFolderId Id="#{folder_id}"/>
                </m:FolderIds>
            </GetFolder>
        </soap:Body>
    </soap:Envelope>
    """
  end

  defp find_item_request({id} = _folder) do
    """
    <?xml version="1.0"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages">
        <soap:Header>
            <t:RequestServerVersion Version="Exchange2010"/>
        </soap:Header>
        <soap:Body>
            <FindItem xmlns="http://schemas.microsoft.com/exchange/services/2006/messages" Traversal="Shallow">
                <ItemShape>
                    <t:BaseShape>Default</t:BaseShape>
                </ItemShape>
                <m:ParentFolderIds>
                    <t:FolderId Id="#{id}"/>
                </m:ParentFolderIds>
            </FindItem>
        </soap:Body>
    </soap:Envelope>
    """
  end

end