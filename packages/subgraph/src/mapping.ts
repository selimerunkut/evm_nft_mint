import { BigInt, Address } from "@graphprotocol/graph-ts"
import {
  YourContract,
  PublicSaleMint
} from "../generated/YourContract/YourContract"
import { PublicSaleMint, Sender } from "../generated/schema"

export function handlePublicSaleMint(event: publicSaleMintEvent): void {

  let senderString = event.params.sender.toHexString()

  let sender = Sender.load(senderString)

  if (sender == null) {
    sender = new Sender(senderString)
    sender.address = event.params.sender
    sender.createdAt = event.block.timestamp
    sender.PublicSaleMintCount = BigInt.fromI32(1)
  }
  else {
    sender.PublicSaleMintCount = sender.PublicSaleMintCount.plus(BigInt.fromI32(1))
  }

  let PublicSaleMint = new PublicSaleMint(event.transaction.hash.toHex() + "-" + event.logIndex.toString())

  PublicSaleMint.numberOfTokens = event.params.numberOfTokens
  PublicSaleMint.sender = senderString
  PublicSaleMint.createdAt = event.block.timestamp
  PublicSaleMint.transactionHash = event.transaction.hash.toHex()

  PublicSaleMint.save()
  sender.save()

}
