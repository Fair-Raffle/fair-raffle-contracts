import { steps } from '../../assets/texts'

export default function Head() {
    return (
        <div className=''>
            <span className='text-[24px]'> {steps.title} </span>
            <br />
            <span className='text-[15px] whitespace-pre-line'> {steps.subtitle} </span>
        </div>
    )
}