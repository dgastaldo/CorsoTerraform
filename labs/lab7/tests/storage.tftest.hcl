# Test eseguiti con provider simulato: nessuna risorsa reale viene creata.
mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  student         = "demo"
}

run "tls_minimo_1_2_e_niente_blob_pubblici" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.min_tls_version == "TLS1_2"
    error_message = "Lo storage account deve imporre TLS 1.2."
  }

  assert {
    condition     = azurerm_storage_account.main.allow_nested_items_to_be_public == false
    error_message = "Lo storage account non deve permettere blob pubblici."
  }
}

run "nome_storage_valido" {
  command = apply

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", azurerm_storage_account.main.name))
    error_message = "Il nome dello storage account non rispetta i vincoli Azure."
  }
}

run "student_non_valido_rifiutato" {
  command = plan

  variables {
    student = "NOME_NON_VALIDO"
  }

  expect_failures = [var.student]
}
