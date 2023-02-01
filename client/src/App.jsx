import './output.css'
import Navbar from './containers/Navbar'
import Steps from './containers/Steps'

function App() {

  return (
    <div className='bg-[#0F1018] h-screen w-screen'>
      <div className='flex flex-col mx-16 max-w-[80rem] mx-auto'>
        <Navbar />
        <Steps />
      </div>
    </div>
  )
}

export default App
