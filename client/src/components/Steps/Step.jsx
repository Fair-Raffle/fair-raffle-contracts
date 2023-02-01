export default function Step({step, abled, hover}) {
    return (
        <div className={`${abled ? '' : 'opacity-[23%]'} ${hover ? 'shadow-step-hover border-[1px] border-[#70769d]' : ''} flex flex-col shadow-step rounded-[2px] flex-row bg-step min-h-[20rem] hover:shadow-step-hover w-full p-4 border-step-current hover:border-2 border-solid hover:border-[#70769d] cursor-pointer`}>
            <span className='text-white text-[14px]'> {step.title} </span>
            <br />
            <span className='text-[#6F80B0] text-[12px] whitespace-pre-line w-2/3'> {step.description} </span>
            <button className='bg-[#0B0D13] text-[#6F80B0] rounded-[13px] text-[12px] whitespace-pre-line mx-auto mb-0 mt-auto px-4 py-1'>
                <span className="text-[20px]">_ _ _ _ _ _ _ _</span>
            </button>
            {/* <input className='bg-[#0B0D13] text-[#6F80B0] rounded-[13px] text-[12px] whitespace-pre-line mx-auto mb-0 mt-auto' placeholder="____________" /> */}
        </div>
    )
}
