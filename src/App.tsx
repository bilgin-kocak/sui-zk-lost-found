import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import { isValidSuiObjectId } from "@mysten/sui.js/utils";
import { Box, Container, Flex, Heading, TextField } from "@radix-ui/themes";
import { useState } from "react";
import { LostItem } from "./LostItem";
import { FoundItem } from "./FoundItem";
import { CreateLostItem } from "./ZKLostFound";
import { LostItems } from "./LostItems";

function App() {
  const [lostData, setLostData] = useState<string>(""); 
  const currentAccount = useCurrentAccount();
  const [counterId, setCounter] = useState(() => {
    const hash = window.location.hash.slice(1);
    return isValidSuiObjectId(hash) ? hash : null;
  });

  console.log(lostData)

  return (
    <>
      <Flex
        position="sticky"
        px="4"
        py="2"
        justify="between"
        style={{
          borderBottom: "1px solid var(--gray-a2)",
        }}
      >
        <Box>
          <Heading>dApp Starter Template</Heading>
        </Box>

        <Box>
          <ConnectButton />
        </Box>
      </Flex>
      <Container>
        <LostItems></LostItems>

        
        <Container
          mt="5"
          pt="2"
          px="4"
          style={{ background: "var(--gray-a2)", minHeight: 500 }}
        >
          
          {currentAccount ? (
            <>
            <TextField.Input placeholder="Write your lost item indentifier" onChange={(e) => setLostData(e.target.value)} value={lostData}/>
              {counterId && (
                <LostItem id={counterId} />
              )}
              <CreateLostItem
                lostData={lostData}
                onCreated={(id) => {
                  window.location.hash = id;
                  setCounter(id);
                }}
              />

              <FoundItem
                lostData={lostData}
                onCreated={(id) => {
                  window.location.hash = id;
                  setCounter(id);
                }}
              />
            </>
          ) : (
            <Heading>Please connect your wallet</Heading>
          )}
        </Container>
      </Container>
    </>
  );
}

export default App;
