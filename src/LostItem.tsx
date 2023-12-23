import {
  useSignAndExecuteTransactionBlock,
  useSuiClient,
  useSuiClientQuery,
} from "@mysten/dapp-kit";
import { SuiObjectData } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Button, Flex, Heading, Text } from "@radix-ui/themes";
import { useNetworkVariable } from "./networkConfig";

export  function LostItem({ id }: { id: string }) {
  const client = useSuiClient();
  // const currentAccount = useCurrentAccount();
  const counterPackageId = useNetworkVariable("counterPackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();
  const { data, isPending, error, refetch } = useSuiClientQuery("getObject", {
    id,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  const executeMoveCall = (method: "increment" | "reset") => {
    const txb = new TransactionBlock();

    if (method === "reset") {
      txb.moveCall({
        arguments: [txb.object(id), txb.pure.u64(0)],
        target: `${counterPackageId}::counter::set_value`,
      });
    } else {
      txb.moveCall({
        arguments: [txb.object(id)],
        target: `${counterPackageId}::counter::increment`,
      });
    }

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
          client.waitForTransactionBlock({ digest: tx.digest }).then(() => {
            refetch();
          });
        },
      },
    );
  };

  if (isPending) return <Text>Loading...</Text>;

  if (error) return <Text>Error: {error.message}</Text>;

  if (!data.data) return <Text>Not found</Text>;

  console.log("Object Data", data.data);

  // const ownedByCurrentAccount =
  //   getCounterFields(data.data)?.owner === currentAccount?.address;

  return (
    <>
      <Heading size="3">Lost Item Object Id: {id}</Heading>

      <Flex direction="column" gap="2">
        <Text>Lost Item: {getCounterFields(data.data)?.value}</Text>
        <Text>Lost Item Hash: {getCounterFields(data.data)?.name?.fields?.name}</Text>
        <Flex direction="row" gap="2">
          <Button onClick={() => executeMoveCall("increment")}>
            Increment
          </Button>
          {/* {ownedByCurrentAccount ? (
            <Button onClick={() => executeMoveCall("reset")}>Reset</Button>
          ) : null} */}
        </Flex>
      </Flex>
    </>
  );
}
function getCounterFields(data: SuiObjectData) {
  if (data.content?.dataType !== "moveObject") {
    return null;
  }

  return data.content.fields as { value: number; owner: string, name: { fields: { name: string } } };
}
