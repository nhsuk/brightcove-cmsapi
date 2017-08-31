def stub_counts(count)
  stub_request(:get, %r{#{Brightcove::Cmsapi::API_ROOT}/my_account_id/counts/.*})
    .to_return(
      body: "{
        \"count\": #{count}
      }",
      headers: { 'Content-Type': 'application/json' }
    )
end
