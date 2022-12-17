export default function Layout({ children }) {
    return (
        <>
        <div className='bg-slate-800'>
            <main>{children}</main>
        </div>
        </>
    )
}