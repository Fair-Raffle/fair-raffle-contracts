import Header from '../components/Steps/Head';
import Step from '../components/Steps/Step';
import { steps } from '../assets/texts';

export default function Steps() {
    return (
        <div className='flex flex-col'>
            <Header />
            <div className='flex flex-col w-[65rem] mx-auto space-y-4 mt-8'>
                <div className='flex shadow-step-head bg-step-head py-1'>
                    <span className='text-[24px] font-700 mx-auto'> {steps.subtitle2} </span>
                </div>
                <div className='flex flex-row space-x-2'>
                    <Step step={steps.steps[0]} abled={true}/>
                    <Step step={steps.steps[1]} abled={true} hover={true}/>
                    <Step step={steps.steps[2]} abled={false}/>
                    <Step step={steps.steps[3]} abled={false}/>
                    {/* {
                        steps.steps.map((step, index) => {
                            return (
                                <Step key={index} step={step} />
                            )
                        }
                        )
                    } */}
                </div>

            </div>
            
        </div>
    )
}