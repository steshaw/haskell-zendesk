{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module TicketsSpec (ticketsSpec) where

import qualified Data.Aeson as Aeson
import Data.Aeson.QQ (aesonQQ)
import Zendesk

import Test.Hspec
import Test.Hspec.Wai
import Test.Hspec.Wai.JSON (json)

emptyCommentCreate = TicketCommentCreate
  { ticketCommentCreateBody = Nothing
  , ticketCommentCreateHtmlBody = Nothing
  , ticketCommentCreatePublic = Nothing
  , ticketCommentCreateAuthorId = Nothing
  }

jsonTicket :: Aeson.Value
jsonTicket = [aesonQQ|
{
  "ticket": {
    "subject": "Awesome Company — Trial",
      "comment": {
        "html_body": "Wilma Flintstone at <b>Awesome Company</b> signed up for a trial",
        "public": false
    },
    "requester": {
      "email": "steven+wilma@steshaw.org",
      "name": "Wilma Flintstone"
    }
  }
}
|]

privateTicket :: TicketCreate
privateTicket = TicketCreate
  { ticketCreateSubject = Just "Awesome Company — Trial"
  , ticketCreateComment = emptyCommentCreate
    { ticketCommentCreateHtmlBody = Just
        "Wilma Flintstone at <b>Awesome Company</b> signed up for a trial"
    , ticketCommentCreatePublic = Just False
    }
  , ticketCreateRequester = Just Requester
      { requesterLocaleId = Nothing
      , requesterName = Just "Wilma Flintstone"
      , requesterEmail = Just "steven+wilma@steshaw.org"
    }
  }

ticketsSpec :: Spec
ticketsSpec = do
  describe "TicketCreate" $ do
    it "convert to JSON" $ do
      Aeson.toJSON privateTicket `shouldBe` jsonTicket
    it "converts from JSON" $ do
      Aeson.fromJSON jsonTicket `shouldBe` Aeson.Success privateTicket

  describe "POST /tickets.json" $ do

    it "responds okay with a subject" $ do
      (subdomain, username, password) <- Zendesk.env
      let comment = emptyCommentCreate { ticketCommentCreateBody = Just "A body" }
      let ticket = TicketCreate (Just "A subject") comment Nothing
      run subdomain username password (`createTicket` ticket)
        `shouldReturn` Right (TicketCreateResponse Nothing)

    it "responds okay without a subject" $ do
      (subdomain, username, password) <- Zendesk.env
      let comment = emptyCommentCreate { ticketCommentCreateBody = Just "A body" }
      let ticket = TicketCreate Nothing comment Nothing
      run subdomain username password (`createTicket` ticket)
        `shouldReturn` Right (TicketCreateResponse Nothing)

    it "can create a private ticket (with private comment)" $ do
      (subdomain, username, password) <- Zendesk.env
      let ticket = privateTicket
      run subdomain username password (`createTicket` ticket)
       `shouldReturn` Right (TicketCreateResponse Nothing)
