import {
    useCurrentAccount,
    useSignAndExecuteTransactionBlock,
    useSuiClient,
    useSuiClientQuery,
  } from "@mysten/dapp-kit";
  import { SuiObjectData } from "@mysten/sui.js/client";
  import { TransactionBlock } from "@mysten/sui.js/transactions";
  import { Button, Flex, Heading, Text } from "@radix-ui/themes";
  import { useNetworkVariable } from "./networkConfig";
  
  export function LostItems() {
    const client = useSuiClient();
    const currentAccount = useCurrentAccount();
    const counterPackageId = useNetworkVariable("counterPackageId");
    const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();
    const { data, isPending, error, refetch } = useSuiClientQuery("getObject", {
      id: "0xb035c366ed96cb111e9a36321dfd11054e3ac9baa635fd4dcfd324699a4eb37c",
      options: {
        showContent: true,
        showOwner: true,
      },
    });
  
   
    if (isPending) return <Text>Loading...</Text>;
  
    if (error) return <Text>Error: {error.message}</Text>;
  
    if (!data.data) return <Text>Not found</Text>;
  
    console.log("Object Data", data.data);
  
    return (
      <>
        <Heading size="3">Lost Items Object</Heading>

        <Flex direction="column" gap="2">
          <Text>Balance: {data.data?.content?.fields?.balance}</Text>
          <Text>Lost Item 1 Object Id: {data.data?.content?.fields?.items?.fields?.id?.id}</Text>
          <Flex direction="row" gap="2">
            
          </Flex>
        </Flex>
      </>
    );
  }
