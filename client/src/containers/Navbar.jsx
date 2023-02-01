export default function Navbar() {
  return (
    <div className="flex flex-row h-[10vh]">
      <div className="flex flex-row my-auto">
        <span className="text-[44px] text-white font-bebas">
          <span>FAIR</span>
          <span className="text-[#A5FF4C]">RAFFLE</span>
          <span>.IO</span>
        </span>
      </div>
      <div className="flex flex-row ml-auto mr-0 my-auto space-x-4">
        <span className="text-white my-auto hover:cursor-pointer"> FOR ES </span>
        <span className="text-white my-auto hover:cursor-pointer"> FAIR RAFFLE TOOL </span>
        <span className="text-white border-2 border-white px-4 py-1 hover:cursor-pointer">
          CONNECT WALLET
        </span>
      </div>
    </div>
  );
}
