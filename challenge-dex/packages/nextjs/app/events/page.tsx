"use client";

import type { NextPage } from "next";
import { formatEther } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-eth";

const Events: NextPage = () => {
  const { data: EthToTokenEvents, isLoading: isEthToTokenEventsLoading } = useScaffoldEventHistory({
    contractName: "DEX",
    eventName: "EthToTokenSwap",
  });

  const { data: tokenToEthEvents, isLoading: isTokenToEthEventsLoading } = useScaffoldEventHistory({
    contractName: "DEX",
    eventName: "TokenToEthSwap",
  });

  const { data: liquidityProvidedEvents, isLoading: isLiquidityProvidedEventsLoading } = useScaffoldEventHistory({
    contractName: "DEX",
    eventName: "LiquidityProvided",
  });

  const { data: liquidityRemovedEvents, isLoading: isLiquidityRemovedEventsLoading } = useScaffoldEventHistory({
    contractName: "DEX",
    eventName: "LiquidityRemoved",
  });

  const { data: approvalEvents, isLoading: isApprovalEventsLoading } = useScaffoldEventHistory({
    contractName: "Balloons",
    eventName: "Approval",
  });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        {isEthToTokenEventsLoading ? (
          <div className="flex justify-center items-center mt-10">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div>
            <div className="text-center mb-4">
              <span className="block text-2xl font-bold">ETH To Balloons Events</span>
            </div>
            <div className="overflow-x-auto shadow-lg">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-primary">Address</th>
                    <th className="bg-primary">Amount of ETH in</th>
                    <th className="bg-primary">Amount of Balloons out</th>
                  </tr>
                </thead>
                <tbody>
                  {!EthToTokenEvents || EthToTokenEvents.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="text-center">
                        No events found
                      </td>
                    </tr>
                  ) : (
                    EthToTokenEvents?.map((event, index) => {
                      return (
                        <tr key={index}>
                          <td className="text-center">
                            <Address address={event.args.swapper} />
                          </td>
                          <td>{parseFloat(formatEther(event.args.ethInput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.tokenOutput || 0n)).toFixed(4)}</td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {isTokenToEthEventsLoading ? (
          <div className="flex justify-center items-center mt-10">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="mt-8">
            <div className="text-center mb-4">
              <span className="block text-2xl font-bold">Balloons To ETH Events</span>
            </div>
            <div className="overflow-x-auto shadow-lg">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-primary">Address</th>
                    <th className="bg-primary">Amount of Balloons In</th>
                    <th className="bg-primary">Amount of ETH Out</th>
                  </tr>
                </thead>
                <tbody>
                  {!tokenToEthEvents || tokenToEthEvents.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="text-center">
                        No events found
                      </td>
                    </tr>
                  ) : (
                    tokenToEthEvents?.map((event, index) => {
                      return (
                        <tr key={index}>
                          <td className="text-center">
                            <Address address={event.args.swapper} />
                          </td>
                          <td>{parseFloat(formatEther(event.args.tokensInput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.ethOutput || 0n)).toFixed(4)}</td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {isLiquidityProvidedEventsLoading ? (
          <div className="flex justify-center items-center mt-10">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="mt-8">
            <div className="text-center mb-4">
              <span className="block text-2xl font-bold">Liquidity Provided Events</span>
            </div>
            <div className="overflow-x-auto shadow-lg">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-primary">Address</th>
                    <th className="bg-primary">Amount of ETH In</th>
                    <th className="bg-primary">Amount of Balloons In</th>
                    <th className="bg-primary">Lİquidity Minted</th>
                  </tr>
                </thead>
                <tbody>
                  {!liquidityProvidedEvents || liquidityProvidedEvents.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="text-center">
                        No events found
                      </td>
                    </tr>
                  ) : (
                    liquidityProvidedEvents?.map((event, index) => {
                      return (
                        <tr key={index}>
                          <td className="text-center">
                            <Address address={event.args.liquidityProvider} />
                          </td>
                          <td>{parseFloat(formatEther(event.args.ethInput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.tokensInput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.liquidityMinted || 0n)).toFixed(4)}</td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {isLiquidityRemovedEventsLoading ? (
          <div className="flex justify-center items-center mt-10">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="mt-8 mb-8">
            <div className="text-center mb-4">
              <span className="block text-2xl font-bold">Liquidity Removed Events</span>
            </div>
            <div className="overflow-x-auto shadow-lg mb-5">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-primary">Address</th>
                    <th className="bg-primary">Amount of ETH Out</th>
                    <th className="bg-primary">Amount of Balloons Out</th>
                    <th className="bg-primary">Liquidity Withdrawn</th>
                  </tr>
                </thead>
                <tbody>
                  {!liquidityRemovedEvents || liquidityRemovedEvents.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="text-center">
                        No events found
                      </td>
                    </tr>
                  ) : (
                    liquidityRemovedEvents?.map((event, index) => {
                      return (
                        <tr key={index}>
                          <td className="text-center">
                            <Address address={event.args.liquidityRemover} />
                          </td>
                          <td>{parseFloat(formatEther(event.args.ethOutput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.tokensOutput || 0n)).toFixed(4)}</td>
                          <td>{parseFloat(formatEther(event.args.liquidityWithdrawn || 0n)).toFixed(4)}</td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {isApprovalEventsLoading ? (
          <div className="flex justify-center items-center mt-10">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="mt-8 mb-8">
            <div className="text-center mb-4">
              <span className="block text-2xl font-bold text-green-600">Approve Events (Balloons)</span>
            </div>
            <div className="overflow-x-auto shadow-lg mb-5">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-green-600 text-white">Owner</th>
                    <th className="bg-green-600 text-white">Spender (DEX)</th>
                    <th className="bg-green-600 text-white">Amount Approved (BAL)</th>
                  </tr>
                </thead>
                <tbody>
                  {!approvalEvents || approvalEvents.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="text-center">
                        No approve events yet. Try approving the DEX to spend your BAL!
                      </td>
                    </tr>
                  ) : (
                    approvalEvents?.map((event, index) => (
                      <tr key={index} className="hover:bg-green-50">
                        <td className="text-center">
                          <Address address={event.args.owner} />
                        </td>
                        <td className="text-center">
                          <Address address={event.args.spender} />
                        </td>
                        <td className="text-center font-medium">
                          {parseFloat(formatEther(event.args.value || 0n)).toFixed(4)} BAL
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default Events;
