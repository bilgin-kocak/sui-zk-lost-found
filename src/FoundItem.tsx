import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Button, Container } from "@radix-ui/themes";
import {
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { useNetworkVariable } from "./networkConfig";

export function FoundItem({
  lostData,
  onCreated,
}: {
  lostData: string;
  onCreated: (id: string) => void;
}) {
  const client = useSuiClient();
  const counterPackageId = useNetworkVariable("zkLostAndFoundPackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  return (
    <Container style={{ marginTop: 20 }}>
      <Button
        size="3"
        onClick={() => {
          create();
        }}
      >
        Found Lost Item
      </Button>
    </Container>
  );

  function create() {
    console.log("create");
    const txb = new TransactionBlock();
    const lost_items = txb.object("0xb035c366ed96cb111e9a36321dfd11054e3ac9baa635fd4dcfd324699a4eb37c")

    txb.moveCall({
      arguments: [txb.pure.string(lostData || 'hashhashhash'), txb.pure.string('kocakbilgin@gmail.com'), lost_items ],
      target: `${counterPackageId}::zk_lost_and_found::found_lost_item_hash`,
    });

    signAndExecute(
      {
        transactionBlock: txb,
        options: {
          showEffects: true,
          showObjectChanges: true,
        },
      },
      {
        onSuccess: (tx) => {
          client
            .waitForTransactionBlock({
              digest: tx.digest,
            })
            .then(() => {
              const objectId = tx.effects?.created?.[0]?.reference?.objectId;

              if (objectId) {
                onCreated(objectId);
              }
            });
        },
      },
    );
  }
}
